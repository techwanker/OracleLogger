/** run this as as sys **/ spool trace\_my\_session set echo on set
serveroutput on

alter session set container = sales\_reporting;

create role trace\_my\_session\_role; grant trace\_my\_session\_role to
public;

select \* from dba\_role\_privs where granted\_role =
'TRACE\_MY\_SESSION';

create or replace procedure trace\_my\_session(p\_bind in boolean,
p\_wait in boolean) is my\_sid varchar(9); my\_serial# varchar(9); begin
select to\_char(sid), to\_char(serial#) into my\_sid, my\_serial# from
sys.v\_$session s where s.audsid = userenv('sessionid');

::

    dbms_output.put_line('sid ' || my_sid || ' serial# ' ||  my_serial#); 
    dbms_monitor.session_trace_enable (my_sid,my_serial#,binds=>true);

end; / show errors

grant execute on trace\_my\_session to public;

drop public synonym trace\_my\_session sys.trace\_my\_session; create
public synonym trace\_my\_session for sys.trace\_my\_session;

select owner, object\_type from dba\_objects where object\_name =
'TRACE\_MY\_SESSION';

exec trace\_my\_session(p\_bind => true, p\_wait => true);
