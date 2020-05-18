 # create_directory_udump_dir 
    set echo on
 ## Before Running

Before you run this, look at defines.sql and edit 


    @defines
    alter session set container= &&container;

 determines the location of the user trace files
 and creates the directory udump_dir

    create or replace procedure create_directory_udump_dir is
        my_udump_dir_name   varchar(4096);
        sql_text            varchar(4096);
    begin   
        select value into my_udump_dir_name
        from v$diag_info where name = 'Diag Trace'; 
    
        sql_text := 'create or replace directory udump_dir as ''' || my_udump_dir_name || '''';
        execute immediate sql_text;
        
        dbms_output.put_line(sql_text);
    end;
/
    show errors

    create role udump_dir_role;
    grant read on directory udump_dir to udump_dir_role;
    grant udump_dir_role to &&username;

    exec sys.create_directory_udump_dir;
