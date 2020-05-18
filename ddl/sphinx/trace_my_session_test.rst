set echo on

drop procedure trace\_my\_session;

select \* from user\_role\_privs where granted\_role =
'TRACE\_MY\_SESSION'

| select owner, object\_name, object\_type
| from all\_objects where object\_name = 'TRACE\_MY\_SESSION';

drop procedure trace\_my\_session;

exec sys.trace\_my\_session(p\_bind => true, p\_wait => true);

select 'Ticket:' from dual;

select \* from sys.v\_$diag\_sess\_opt\_trace\_records;
