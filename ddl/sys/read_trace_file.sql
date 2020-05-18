
   create or replace function read_trace_file(p_file_name in varchar) 
   return clob is 
       my_udump_dir_name         varchar(4096);
       my_udump_directory_path   varchar(4096);
       my_file_name              varchar(4096);
       incorrect_udump_directory exception;  
   begin
       dbms_output.put_line('Diag Trace');
       select value into my_udump_dir_name 
       from v$diag_info where name = 'Diag Trace';

       dbms_output.put_line('UDUMP_DIR');
       select directory_path into my_udump_directory_path 
       from all_directories where directory_name = 'UDUMP_DIR';

       dbms_output.put_line('Validating');
       if my_udump_directory_path is null then
           dbms_output.put_line ('no UDUMP_DIR directory available to this user');
           raise incorrect_udump_directory;
       end if ;

       if  my_udump_directory_path != my_udump_dir_name then
           dbms_output.put_line ('trace_files_are in ' || my_udump_dir_name || 
              'but directory UDUMP_DIR is "' || my_udump_directory_path || '"');
           raise incorrect_udump_directory;
       end if;
       dbms_output.put_line('returning');
       return read_file('UDUMP_DIR',p_file_name);
   end read_trace_file;
   /
show errors;

set serveroutput on 

declare
    file_text clob;
    my_clob_length pls_integer;
begin
    file_text := read_trace_file('dev18b_ora_26830_job_1.trc');
    if (file_text is null) then
        dbms_output.put_line('file_text is null');
    end if;
    my_clob_length := length(file_text);
    dbms_output.put_line('length of file is ' || to_char(my_clob_length));
    --dbms_output.put_line(file_text);
end;
/
