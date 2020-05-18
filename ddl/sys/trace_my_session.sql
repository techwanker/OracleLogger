/**
    run this as as sys 
**/
spool trace_my_session
set echo on 
set serveroutput on 

alter session set container = sales_reporting;

create role trace_my_session_role;
grant  trace_my_session_role to public;

select * from dba_role_privs 
where granted_role = 'TRACE_MY_SESSION';

create or replace procedure trace_my_session(p_bind in boolean, p_wait in boolean) is
    my_sid varchar(9);
    my_serial# varchar(9);
begin
    select to_char(sid), to_char(serial#)
    into my_sid, my_serial#
    from  sys.v_$session s
    where s.audsid = userenv('sessionid');

    dbms_output.put_line('sid ' || my_sid || ' serial# ' ||  my_serial#); 
    dbms_monitor.session_trace_enable (my_sid,my_serial#,binds=>true);
end;
/
show errors

grant execute on trace_my_session to public;

drop public synonym trace_my_session  sys.trace_my_session;
create public synonym trace_my_session for sys.trace_my_session;

select owner, object_type 
from dba_objects 
where object_name = 'TRACE_MY_SESSION';

exec trace_my_session(p_bind => true, p_wait => true);

