set echo on
set serveroutput on
spool example_01.lst

begin
   logger.log('a message');
end;
