SET client_min_messages = warning;
CREATE TABLE accounts
(
  id bigserial NOT NULL,
  account_name text,
  balance integer,
  CONSTRAINT accounts_pkey PRIMARY KEY (id),
  CONSTRAINT no_minus CHECK (balance >= 0)
);
RESET client_min_messages;
insert into accounts(account_name, balance) values('joe', 200);
insert into accounts(account_name, balance) values('mary', 50);
CREATE OR REPLACE FUNCTION pg_temp.sub_test()
RETURNS SETOF text AS $$
  local f = function() 
    local p = server.prepare("UPDATE accounts SET balance = balance + $2 WHERE account_name = $1", {"text","int4"})
    p:execute{'joe', 100}
    p:execute{'mary',-100}
    return true
  end 
  local status, err = subtransaction(f) 
  coroutine.yield(tostring(status))

  f = function() 
    local p = server.prepare("UPDATE accounts SET balance = balance + $2 WHERE account_name = $1", {"text","int4"})
    p:execute{'joe', -100}
    p:execute{'mary', 100}
    return true
  end 
  status, err = subtransaction(f) 
  coroutine.yield(tostring(status))
$$ LANGUAGE pllua;
select pg_temp.sub_test();
do $$
local status, result = subtransaction(function() 
server.execute('select 1,'); -- < special SQL syntax error
end);
print (status, result)
status, result = pcall(function() 
server.execute('select 1,'); -- < special SQL syntax error
end);
print (status, result)
print ('done')
$$ language pllua;
