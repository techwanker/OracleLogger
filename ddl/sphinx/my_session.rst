spool my\_session set echo on rem run as sys

@defines

alter session set container = &&container;

drop view my\_session;

drop public synonym my\_session;

select \* from dba\_objects where object\_name = 'MY\_SESSION';

create or replace view my\_session\_vw as select s.SADDR, s.SID,
s.SERIAL#, s.AUDSID , s.PADDR, s.USER#, s.USERNAME, s.COMMAND,
s.OWNERID, s.TADDR, s.LOCKWAIT, s.STATUS , s.SERVER , s.SCHEMA#,
s.SCHEMANAME, s.OSUSER , s.PROCESS, s.MACHINE, s.PORT, s.TERMINAL,
s.PROGRAM, s.TYPE, s.SQL\_ADDRESS, s.SQL\_HASH\_VALUE, s.SQL\_ID ,
s.SQL\_CHILD\_NUMBER, s.SQL\_EXEC\_START , s.SQL\_EXEC\_ID,
s.PREV\_SQL\_ADDR, s.PREV\_HASH\_VALUE, s.PREV\_SQL\_ID,
s.PREV\_CHILD\_NUMBER, s.PREV\_EXEC\_START, s.PREV\_EXEC\_ID,
s.PLSQL\_ENTRY\_OBJECT\_ID, s.PLSQL\_ENTRY\_SUBPROGRAM\_ID,
s.PLSQL\_OBJECT\_ID, s.PLSQL\_SUBPROGRAM\_ID, s.MODULE , s.MODULE\_HASH,
s.ACTION , s.ACTION\_HASH, s.CLIENT\_INFO, s.FIXED\_TABLE\_SEQUENCE,
s.ROW\_WAIT\_OBJ#, s.ROW\_WAIT\_FILE# , s.ROW\_WAIT\_BLOCK#,
s.ROW\_WAIT\_ROW#, s.TOP\_LEVEL\_CALL#, s.LOGON\_TIME, s.LAST\_CALL\_ET,
s.PDML\_ENABLED, s.FAILOVER\_TYPE, s.FAILOVER\_METHOD, s.FAILED\_OVER,
s.RESOURCE\_CONSUMER\_GROUP, s.PDML\_STATUS, s.PDDL\_STATUS,
s.PQ\_STATUS, s.CURRENT\_QUEUE\_DURATION , s.CLIENT\_IDENTIFIER,
s.BLOCKING\_SESSION\_STATUS, s.BLOCKING\_INSTANCE, s.BLOCKING\_SESSION,
s.FINAL\_BLOCKING\_SESSION\_STATUS, s.FINAL\_BLOCKING\_INSTANCE,
s.FINAL\_BLOCKING\_SESSION , s.SEQ#, s.EVENT# , s.EVENT, s.P1TEXT ,
s.P1, s.P1RAW, s.P2TEXT , s.P2, s.P2RAW, s.P3TEXT , s.P3, s.P3RAW,
s.WAIT\_CLASS\_ID, s.WAIT\_CLASS#, s.WAIT\_CLASS, s.WAIT\_TIME,
s.SECONDS\_IN\_WAIT, s.STATE, s.WAIT\_TIME\_MICRO,
s.TIME\_REMAINING\_MICRO, s.TIME\_SINCE\_LAST\_WAIT\_MICRO,
s.SERVICE\_NAME, s.SQL\_TRACE, s.SQL\_TRACE\_WAITS, s.SQL\_TRACE\_BINDS,
s.SQL\_TRACE\_PLAN\_STATS from sys.v$session s where s.audsid =
userenv('sessionid');

grant select on my\_session\_vw to public;

drop public synonym my\_session; create public synonym my\_session for
my\_session\_vw; grant select on my\_session\_vw to public;

select \* from my\_session; select owner, object\_type, object\_name
from dba\_objects where object\_name='MY\_SESSION';

connect &&username/&&password@&&container;

select \* from my\_session\_vw; select \* from my\_session;

--grant select on
sys.v\_\ :math:`process to public;    --grant select on sys.v_`\ session
to public;
