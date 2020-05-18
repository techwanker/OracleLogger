
/* Explain Plan */
create table cursor_explain_plan (
    explain_plan_hash  varchar(44) not null,
    explain_plan       clob not null
);

alter table cursor_explain_plan 
add constraint cursor_explain_plan_pk
primary key (explain_plan_hash);

/* SQL */
create table cursor_sql_text (
	sql_text_hash varchar (44) not null,
	sql_text      clob         not null
);


alter table cursor_sql_text 
add constraint cursor_text_pk
primary key (sql_text_hash);

/* Run */
create sequence cursor_info_run_id_seq;
create table cursor_info_run(
    cursor_info_run_id    number(9) not null,
    cursor_info_run_descr clob
);


alter table cursor_info_run 
add constraint cursor_info_run_id 
primary key (cursor_info_run_id);


create sequence cursor_info_id_seq;
create table cursor_info (
	cursor_info_id          number(9) not null,
    cursor_info_run_id      number(9),
	sql_text_hash           varchar(44),
    parse_cpu_micros        number(9),
	parse_elapsed_micros    number(9),
	parse_blocks_read       number(9),
	parse_consistent_blocks number(9),
	parse_current_blocks    number(9),
	parse_lib_miss          number(9),
	parse_row_count         number(9),
    exec_cpu_micros         number(9),
	exec_elapsed_micros     number(9),
	exec_blocks_read        number(9),
	exec_consistent_blocks  number(9),
	exec_current_blocks     number(9),
	exec_lib_miss           number(9),
	exec_row_count          number(9),
    fetch_cpu_micros        number(9),
	fetch_elapsed_micros    number(9),
	fetch_blocks_read       number(9),
	fetch_consistent_blocks number(9),
	fetch_current_blocks    number(9),
	fetch_lib_miss          number(9),
	fetch_row_count         number(9),
	explain_plan_hash       varchar(44)
);


alter table cursor_info 
add constraint cursor_info_pk
primary key (cursor_info_id);

alter table cursor_info
add constraint cursor_info_text_fk
foreign key (sql_text_hash)
references cursor_sql_text;

alter table cursor_info
add constraint cursor_info_plan_fk
foreign key (explain_plan_hash)
references cursor_explain_plan;

alter table cursor_info add constraint 
cursor_info_run_fk foreign key (cursor_info_run_id)
references cursor_info_run;

create or replace view  cursor_info_vw as 
select 
	cursor_info.cursor_info_id,
    cursor_sql_text.sql_text,
    explain_plan,
    parse_cpu_micros,
    parse_elapsed_micros,
    parse_blocks_read,
    parse_consistent_blocks,
    parse_current_blocks,
    parse_lib_miss,
    parse_row_count,
    exec_cpu_micros,
    exec_elapsed_micros,
    exec_blocks_read,
    exec_consistent_blocks,
    exec_current_blocks,
    exec_lib_miss,
    exec_row_count,
    fetch_cpu_micros,
    fetch_elapsed_micros,
    fetch_blocks_read,
    fetch_consistent_blocks,
    fetch_current_blocks,
    fetch_lib_miss,
    fetch_row_count,
    parse_cpu_micros + exec_cpu_micros + fetch_cpu_micros cpu_micros ,
    parse_elapsed_micros + exec_elapsed_micros + fetch_elapsed_micros elapsed_micros ,
    parse_blocks_read + exec_blocks_read + fetch_blocks_read blocks_read ,
    parse_consistent_blocks + exec_consistent_blocks + fetch_consistent_blocks consistent_blocks ,
    parse_current_blocks + exec_current_blocks + fetch_current_blocks current_blocks ,
    parse_lib_miss + exec_lib_miss + fetch_lib_miss lib_miss ,
    parse_row_count + exec_row_count + fetch_row_count row_count
from cursor_info,
     cursor_sql_text,
     cursor_explain_plan
 where cursor_info.sql_text_hash = cursor_sql_text.sql_text_hash and
       cursor_info.explain_plan_hash = cursor_explain_plan.explain_plan_hash;
    

create table cursor_stat (
    cursor_info_id   number(9) not null,
    seq_nbr          number(3) not null,
    operation_depth  number(2) not null, 
    operation        varchar(100),
    consistent_reads number(9),
    physical_reads   number(9),
    physical_writes  number(9),
    elapsed_millis   number(12)
);



alter table cursor_stat add 
constraint cursor_stat_pk 
primary key (cursor_info_id, seq_nbr);




alter table cursor_stat add constraint
cursor_stat_cursor_info_fk foreign key
(cursor_info_id) references
cursor_info;

alter table job_step add cursor_info_run_id number(9);

alter table job_step add constraint job_step_cursor_info_run_fk
foreign key cursor_info_run_id references cursor_info_run;
