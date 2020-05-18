create sequence job_log_id_seq;

create table job_log (    
    job_log_id number(9),
    job_token            varchar(64),
    schema_name          varchar(30),
    process_name         varchar(128),
    thread_name          varchar(128),
    status_msg           varchar(256),
    status_ts 	         timestamp(9),
    start_ts    	 timestamp(9),
    end_ts               timestamp(9),
    log_level            number(1),
    elapsed_millis       number(9),
    sid                  number,
    serial_nbr           number,
    ignore_flg           varchar(1) default 'N' not null,
    module_name          varchar(64),
    classname            varchar(255),
    tracefile_name       varchar(4000),
    msg_lvl              number(1),
    trace_level          number(2),
    directory_name       varchar(128),
    logfile_name         varchar(64),
    tracefile_data       clob,
    tracefile_json       clob,
    abort_stacktrace     clob,
    check ( ignore_flg in ('Y', 'N')) ,
    constraint job_log_pk primary key (job_log_id)
   ); 

create sequence job_step_id_seq;

alter table job_log add constraint job_log_token_uq unique (job_token);

create table job_step (    
    job_step_id             number(9),
    job_log_id 	            number(9),
    step_name               varchar(64),
    classname               varchar(256),
    step_info               varchar(2000),
    start_ts    	    timestamp(9),
    end_ts  		    timestamp(9),
    dbstats                 clob,
    step_info_json          clob,
    --cursor_info_run_id      number(9) references cursor_info_run,
    stacktrace              varchar(4000),
    constraint job_step_pk primary key (job_step_id),
    constraint step_status_fk
	foreign key (job_log_id) references job_log
);

create sequence job_msg_id_seq;

create table job_msg (    
    job_msg_id 	      number(9) not null,
    job_log_id 	      number(9) not null,
    job_step_id       number(9),  
    log_msg_id 		  varchar2(8) not null,
    log_msg 		  varchar2(256),
    log_msg_clob      clob,
    log_msg_ts 		  timestamp (9),
    elapsed_time_milliseconds number(9),
    log_seq_nbr 	  number(18,0) not null,
    caller_name       varchar2(100),
    line_nbr 		  number(5,0),
    call_stack 		  clob,
    log_level 		  number(2,0),
    constraint job_msg_pk primary key (job_log_id, log_seq_nbr)
); 


alter table job_msg 
add constraint job_msg_job_log_fk 
foreign key (job_log_id) 
references job_log(job_log_id);

alter table job_msg 
add constraint job_fk 
foreign key (job_step_id) 
references job_step(job_step_id);

create or replace view job_step_vw as
select
    job_step_id,
    job_log_id,
	step_name,
	classname ,
	step_info,
    start_ts,
    end_ts ,
    end_ts - start_ts elapsed_millis
from job_step;

create or replace view job_log_vw as 
select  
   job_log_id, 
   schema_name,         
   process_name,        
   thread_name,          
   status_msg,                               
   status_ts,                        
   end_ts,                               
   sid,                                      
   serial_nbr,                       
   ignore_flg,    
   module_name,    
   classname,             
   tracefile_name,                 
   end_ts - status_ts elapsed_millis 
from job_log;

