    set echo on
    @defines

    alter session set container = &&container;
    
    select tablespace_name from dba_tablespaces;
 
    grant connect to  &&username identified  by tutorial;
    grant create session to &&username;
    grant create table to &&username;
    grant create procedure to &&username;
    grant create type to &&username;
    grant create view to &&username;
    -- grant create directory to &username;
    grant create sequence to &&username;

    alter user &&username default tablespace &&tablespace_name;
    alter user &&username quota unlimited on &&tablespace_name;
    -- 
    grant execute on sys.utl_file to &&username with grant option;
    --grant execute on sys.dbms_pipe to &&username with grant option;
    --#grant select on sys.v_$session to &username with grant option;
    --#grant select on sys.v_$mystat to &username with grant option;
    --#grant select on sys.v_$sesstat  to &username with grant option;
    --#grant execute on sys.dbms_lock to &username with grant option;
    --#grant execute on sys.utl_http to &username with grant option;
    
    drop directory udump_dir;
    create directory udump_dir as '&&udump_directory';
    create public synonym udump_dir for udump_dir;
    grant read on directory udump_dir to &username;
    
    drop directory job_msg_dir;
    create directory job_msg_dir as '&&job_msg_directory';
    grant read, write on directory job_msg_dir to &username;

    drop directory tmp_dir;
    create directory tmp_dir as '&&tmp_directory';
    grant read, write on directory tmp_dir to &username;

    drop public synonym job_msg_dir;
    create public synonym job_msg_dir for job_msg_dir;


