--%```
set serveroutput on
set echo on
spool example_log_suite.lst
--%```

--%# Logging example


--%## example_05
--%```
create or replace 
procedure example_06
is
begin
    for i in 1 .. 10000
    loop
        for lvl in 1 .. 9
        loop
    	    logger.log('lvl is ' || lvl,lvl);
        end loop;
    end loop;
end;
--%```
/

/

--%## Example usage
--%
--%
--%* begin_log (logfile_name, p_log_level)
--%
--%  A logfile will be created in the *job_msg_dir* directory and
--%  unless other filters are applied messages of level 3 and lower
--%  will be written
--%
--%* set_caller_level(unit_name,level)
--%  
--%  All messages for procedure *example_05* of with a level of 8
--%  or less will be written  
--%```
declare
    token varchar(32);
    logname varchar(32) := to_char(job_log_id_seq.nextval) || '.log';
begin
   logger.set_debug;
   logger.begin_log(logfile_name => logname, log_level => 3);
   logger.set_caller_level('example_06',4);
   example_06;
end;
--%```
/

## The output
--%```
--%1,"2020-05-15T18:23:57.422520000","severe","EXAMPLE_01",4,,,""
--%2,"2020-05-15T18:23:57.427165000","warning","EXAMPLE_01",5,,,""
--%3,"2020-05-15T18:23:57.429084000","undefined","EXAMPLE_01",6,,,""
--%1,"2020-05-15T18:23:57.439742000","lvl is 1","EXAMPLE_04",8,,,""
--%2,"2020-05-15T18:23:57.441323000","lvl is 2","EXAMPLE_04",8,,,""
--%3,"2020-05-15T18:23:57.442867000","lvl is 3","EXAMPLE_04",8,,,""
--%1,"2020-05-15T18:23:57.453696000","lvl is 1","EXAMPLE_05",7,,,""
--%2,"2020-05-15T18:23:57.455170000","lvl is 2","EXAMPLE_05",7,,,""
--%3,"2020-05-15T18:23:57.456750000","lvl is 3","EXAMPLE_05",7,,,""
--%```
