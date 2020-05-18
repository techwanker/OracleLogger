set timing on
set echo on
set serveroutput on
begin
	  for i in 1 .. 10000
	  loop
	      pllog.log2('m');
              --dbms_output.put_line(to_char(i));
      end loop;
end ;
/	      
