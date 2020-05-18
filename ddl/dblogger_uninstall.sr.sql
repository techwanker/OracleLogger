/* logger objects */
drop sequence cursor_info_id_seq;
drop sequence cursor_info_run_id_seq;
drop sequence job_log_id_seq;
drop sequence job_msg_id_seq;   
drop sequence job_step_id_seq;
drop table cursor_explain_plan cascade constraint;
drop table cursor_info cascade constraint;                                          
drop table cursor_info_run cascade constraint;                                   
drop table cursor_sql_text cascade constraint;                                             
drop table cursor_stat cascade constraint;
drop view cursor_info_vw;
drop table job_log cascade constraint;
drop table job_msg cascade constraint;                                  
drop table job_step cascade constraint;
drop view job_log_vw;          
drop view job_step_vw;   
/* application object */
drop package logger;
drop package pllogger;
drop package pllog;
