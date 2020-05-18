set echo on

drop procedure trace_my_session;

select * from user_role_privs
where granted_role = 'TRACE_MY_SESSION'

select owner, object_name, object_type  
from all_objects 
where object_name = 'TRACE_MY_SESSION';

drop procedure trace_my_session;

exec sys.trace_my_session(p_bind => true, p_wait => true);

select 'Ticket:' from dual;

select * from sys.v_$diag_sess_opt_trace_records;
