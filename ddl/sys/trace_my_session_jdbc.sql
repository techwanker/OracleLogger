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

create or replace procedure trace_my_session_jdbc(p_bind in pls_integer default 1, p_wait in pls_integer default 1) is
    my_sid varchar(9);
    my_serial# varchar(9);
    my_binds boolean;
    my_waits boolean;
begin
    if (p_bind = 0) then my_binds := false; else my_binds  := true; end if;
    if (p_wait = 0) then my_waits := false; else my_waits  := true; end if;

    select to_char(sid), to_char(serial#)
    into my_sid, my_serial#
    from  sys.v_$session s
    where s.audsid = userenv('sessionid');

    dbms_output.put_line('sid ' || my_sid || ' serial# ' ||  my_serial#); 
    dbms_monitor.session_trace_enable (my_sid,my_serial#,binds=>my_binds,waits=>my_waits);
end;
/
show errors

grant execute on trace_my_session_jdbc to public;
grant execute on trace_my_session to public;

drop public synonym trace_my_session  sys.trace_my_session;

select owner, object_type 
from dba_objects 
where object_name = 'TRACE_MY_SESSION';

exec trace_my_session_jdbc(p_bind => 1, p_wait => 1);

