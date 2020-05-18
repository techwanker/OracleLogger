set echo on
set serveroutput on
spool 02_log_to_file.lst

begin
   logger.begin_log(logfile_directory => 'TMP_DIR', logfile_name => '02_log_to_file.log');
   logger.log('a message');
end;
/
