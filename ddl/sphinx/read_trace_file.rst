| create or replace function read\_trace\_file(p\_file\_name in varchar)
return clob is my\_udump\_dir\_name varchar(4096);
my\_udump\_directory\_path varchar(4096); my\_file\_name varchar(4096);
incorrect\_udump\_directory exception;
|  begin dbms\_output.put\_line('Diag Trace'); select value into
my\_udump\_dir\_name from v$diag\_info where name = 'Diag Trace';

::

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

end read\_trace\_file; / show errors;

set serveroutput on

declare file\_text clob; my\_clob\_length pls\_integer; begin file\_text
:= read\_trace\_file('dev18b\_ora\_26830\_job\_1.trc'); if (file\_text
is null) then dbms\_output.put\_line('file\_text is null'); end if;
my\_clob\_length := length(file\_text); dbms\_output.put\_line('length
of file is ' \|\| to\_char(my\_clob\_length));
--dbms\_output.put\_line(file\_text); end; /
