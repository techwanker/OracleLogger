--#<
set echo on 
spool logger.pkb.sr.lst
--#>
CREATE OR REPLACE PACKAGE BODY logger
is
  g_debug                 boolean := false;
  g_job_msg_dir           varchar (32) := 'JOB_MSG_DIR';
  g_logfile_name          varchar(255);

  
  type logger_dtl_type is table of logger_dtl%rowtype index by varchar(64);
   
  logger_dtls logger_dtl_type;

  g_job_log job_log%rowtype;
    
  function format_timestamp(timestamp in timestamp)
  return varchar 
  is
    my_timestamp varchar(256) :=  to_char (current_timestamp, 'YYYY-MM-DD HH24:MI:SSXFF');
  begin
    my_timestamp := replace(my_timestamp,' ','T');
    return my_timestamp;
  end format_timestamp;

  function  logger_message_formatter  (
    job_log_id    in   pls_integer,
    job_msg_id    in   pls_integer,
    log_msg       in   varchar,
    log_level     in   pls_integer,
    caller_name   in   varchar default null,
    line_number   in   pls_integer default null,
    call_stack    in   boolean default false,
    separator     in   varchar default ','
   ) return varchar 
  is
    my_log_msg  varchar2(32767) := REPLACE (log_msg, '"', '""');
    my_log_entry varchar2(32767);
    my_timestamp varchar(256);
    stack varchar(32767);
       -- my_text_field_end_separator varchar)  := '",';
  begin
    my_timestamp := format_timestamp(current_timestamp);

    if call_stack then 
      stack := dbms_utility.format_call_stack;
    end if;
      --      dbms_output.put_line('my_timestamp '||  my_timestamp);
    my_log_entry :=
      log_level    || separator ||
      '"' ||my_timestamp  || '"' || separator ||
      '"' || my_log_msg   || '"' || separator ||
      '"' || caller_name  || '"' || separator ||
      line_number  || separator  ||
      job_log_id   || separator ||
      job_msg_id   || separator ||
      '"' || stack || '"';
	 -- dbms_output.put_line('log entry: ' || my_log_entry);
      return my_log_entry;
    end;

  function get_job_token 
  return varchar 
  is begin
    return format_timestamp(current_timestamp);
  end;

  function get_new_job_log_id 
  return number 
  is begin
    return job_log_id_seq.nextval;
  end;

  --%#Tracing
  --%<
  procedure set_trace (trace_level in pls_integer)
  --%>
  is
  begin
    DBMS_TRACE.set_plsql_trace (trace_level);
  end set_trace;

  --%<
  function get_my_tracefile_name 
  return varchar 
  --%>
  is
    tracefile_name varchar(4096);
    begin
        select value into tracefile_name
        from v$diag_info
        where name = 'Default Trace File';

        return tracefile_name;
    end get_my_tracefile_name;

  --%<
  function set_tracefile_identifier(job_nbr in number) 
  return varchar
  --%>
  is
    identifier varchar(32) := 'job_' || to_char(job_nbr);
  begin
    execute immediate 'alter session set tracefile_identifier = ''' || identifier || '''';
    return get_my_tracefile_name;
  end set_tracefile_identifier;

    --%# Job DML 
    --%# job_msg
    
  procedure job_msg_insert (
    job_log_id in pls_integer,
    --           g_next_log_seq_nbr in pls_integer,
    log_msg_id in varchar,
    short_message in varchar,
    log_level in pls_integer,
    caller_name in varchar,
    line_number in pls_integer,
    long_message in varchar
   )
   is
     pragma autonomous_transaction ;
   begin
    
     if log_level = g_snap OR log_level <= g_job_log.msg_lvl then
       insert into job_msg (
         job_msg_id,    job_log_id,        
         -- log_seq_nbr,         
         log_msg_id,    
         log_msg,       log_level,         log_msg_ts,          caller_name,    
         line_nbr,      log_msg_clob
       )
       values(
         log_msg_id,    job_log_id,    
	 -- g_next_log_seq_nbr,  
         log_msg_id,   
         short_message, log_level,     current_timestamp,   caller_name,
         line_number,   long_message
      );
      end if;
   end;

    --%# job_log

  procedure job_log_insert(rec in job_log%rowtype) is
  begin
    insert into job_log (    
      job_log_id,     process_name,    thread_name,
      status_msg,     status_ts,       tracefile_name,
      classname,      schema_name,     module_name, 
      job_token,      logfile_name
     ) values (
       rec.job_log_id,  rec.process_name,   rec.thread_name,
       rec.status_msg,  current_timestamp,  rec.tracefile_name,
       rec.classname,   rec.schema_name,  rec.module_name, 
       rec.job_token,   rec.logfile_name
     );

    end;

  function job_step_insert (
    step_name   in varchar, 
    step_info   in varchar default null, 
    classname   in varchar default null,     
    stacktrace  in varchar default null
  ) return number
  is 
    my_job_step_id number;
  begin
    insert into job_step (
      job_step_id,   job_log_id, step_name, step_info, 
      classname,     start_ts,   stacktrace
    ) values (
      job_step_id_seq.nextval, g_job_log.job_log_id, step_name, step_info, 
      classname,   current_timestamp,   stacktrace
    ) returning job_step_id into my_job_step_id;
    return my_job_step_id;
  end job_step_insert;
   
  procedure job_step_finish (step_id in number) is 
  begin
    update job_step 
    set end_ts = systimestamp
    where job_step_id = step_id;
  end job_step_finish;

  procedure begin_log ( 
    logfile_name   in varchar,
    logfile_directory in varchar default 'JOB_MSG_DIR',
    process_name in varchar default null,
    log_set      in varchar default null,
    classname    in varchar default null,
    module_name  in varchar default null,
    status_msg   in varchar default null,
    thread_name  in varchar default null,
    log_level    in pls_integer default G_INFO,
    trace_level  in pls_integer default G_INFO)
    --%>
    is
      my_tracefile_name varchar(256);
      my_job_token varchar(64) := get_job_token;
    
    begin
      if g_debug then
        dbms_output.put_line('begin_log() logfile_name "' || logfile_name || '"');
      end if;
      g_job_log.logfile_name := logfile_name;
      g_job_log.directory_name := logfile_directory;
        --g_job_log.job_log_id   := job_log_id_seq.nextval;
      g_job_log.process_name := process_name;
      g_job_log.classname    := classname;
      g_job_log.module_name  := module_name;
      g_job_log.status_msg   := status_msg;
      g_job_log.thread_name  := thread_name;
      g_job_log.job_token    := my_job_token;
      g_job_log.logfile_name := logfile_name;
      g_job_log.trace_level  := trace_level;
      g_job_log.start_ts     := current_timestamp;
      g_job_log.log_level    := log_level;

      set_trace(trace_level);

      my_tracefile_name := set_tracefile_identifier(g_job_log.job_log_id);
      set_action('begin_job ' || to_char(g_job_log.job_log_id)); 

         
   end begin_log;
 
    --%~~~<
  FUNCTION begin_job ( 
    process_name in varchar,
    log_set      in varchar default null,
    classname    in varchar default null,
    module_name  in varchar default null,
    status_msg   in varchar default null,
    thread_name  in varchar default null,
    logfile_name   in varchar default null,
    logfile_directory in varchar default 'JOB_MSG_DIR',
    log_level    in pls_integer default G_INFO,
    trace_level  in pls_integer default G_INFO)
    return varchar
   --%>
   is
     my_tracefile_name varchar(256);
     my_job_token varchar(64) := get_job_token;
     my_logfile_name varchar(64);
   begin
     dbms_output.put_line('begin_job logfile_name "' || logfile_name);
    
     g_job_log.job_log_id := job_log_id_seq.nextval;

     if logfile_name is not null then
       my_logfile_name := logfile_name;
     else 
       my_logfile_name := my_job_token || '-' || g_job_log.job_log_id  ||
                               '.log';
     end if;
 
     begin_log (
	    logfile_name   => my_logfile_name,
            logfile_directory => logfile_directory,
            process_name => process_name,
            log_set      => log_set,
            classname    => classname,
            module_name  => module_name,
            status_msg   => status_msg,
            thread_name  => thread_name,
            log_level    => log_level,
            trace_level  => trace_level  
     );

     set_action('begin_job ' || to_char(g_job_log.job_log_id)); 
     job_log_insert ( g_job_log);

     return my_job_token;
   end begin_job;
   
 

  procedure end_job
  --::* update job_log.status_id to 'C' and status_msg to 'DONE'
  --::>
  is
       PRAGMA AUTONOMOUS_TRANSACTION;
  begin
       set_action('end_job');
       update job_log
       set
              SID = NULL,
              status_msg = 'DONE',
              status_ts = SYSDATE
        where job_log_id = g_job_log.job_log_id;

      commit;
      set_action('end_job complete');
  end end_job;
   
  procedure abort_job(exception_msg in varchar default null,
		stacktrace in varchar default null)
  --::* procedure abort_job
  --::* update job_log
  --::* elapsed_time
  --::* status_id = 'I'
  --::* status_msg = 'ABORT'
  --::>
  is
       PRAGMA AUTONOMOUS_TRANSACTION;
       -- elapsed_tm   INTERVAL DAY TO SECOND;
       stack   varchar (32767);
  begin
        set_action('abort_job');
        -- g_process_end_tm := current_timestamp;
        -- elapsed_tm := g_process_end_tm - g_process_start_tm;
      
        if stacktrace is not null then
            stack := stacktrace;
        else
            stack := DBMS_UTILITY.format_call_stack ();
        end if;

        update job_log
        set  SID = NULL,
             status_msg = 'ABORT',
             status_ts = SYSDATE,
             abort_stacktrace = stack
        where job_log_id = g_job_log.job_log_id;

        COMMIT;
        set_action('abort_job complete');
  end abort_job;

  procedure set_debug(debug boolean default true) 
  is
  begin
        g_debug := debug;
  end;


  procedure set_action ( action in varchar ) is
  begin
            dbms_application_info.set_action(substr(action, 1, 64)) ;
  end set_action ;

  procedure set_module ( module_name in varchar, action_name in varchar )
  is
  begin
            dbms_application_info.set_module(module_name, action_name) ;
  end set_module ;

  function open_log_file (
        directory_name in varchar,
        file_name in varchar, 
        headers in boolean default true)
  return utl_file.file_type
   --
   --% opens a log file with the specified file name in the directory g_job_msg_dir
  is
      my_directory_path varchar2(4000);
      my_handle utl_file.file_type;
  begin
      if (g_debug) then
          dbms_output.put_line('open_log_file() dir: "' || directory_name || 
                           '" file: "' || file_name || '"');
      end if;
      my_handle := utl_file.fopen(directory_name,file_name,'a');
      return my_handle;
  end open_log_file;

  function get_directory_path return varchar is
       -- todo see if grants are wrong, permission must be granted to the user
       cursor directory_cur is
       select  owner, directory_name, directory_path
       from    all_directories
       where   directory_name = g_job_msg_dir;
 
       directory_rec directory_cur%rowtype;

  begin
        open directory_cur;
        fetch directory_cur into directory_rec;
        dbms_output.put_line('owner: '           || directory_rec.owner ||
                           ' directory_name: ' || directory_rec.directory_name ||
                           ' directory_path: ' || directory_rec.directory_path);
       close directory_cur;

       return directory_rec.directory_path;
  end get_directory_path;
  --::<
  function basename (full_path in varchar,
                     suffix    in varchar default null,
                     separator in char default '/')
  return varchar
      --:: like bash basename or gnu basename, returns the filename of a path optionally
      --:: stripping the specified file extension
      --::>
  is
       my_basename varchar(256);
  begin
        dbms_output.put_line('basename ' || full_path);
        my_basename := substr(full_path, instr(full_path,separator,-1)+1);
        dbms_output.put_line('my_basename' || my_basename);
        if suffix is not null then
            my_basename := substr(my_basename, 1, instr(my_basename, suffix, -1)-1);
        end if;

       return my_basename;
  end basename;
  
  function get_my_tracefile return clob is
  begin
     return get_tracefile(basename(get_my_tracefile_name));
  end get_my_tracefile;

  function get_file(directory in varchar, file_name in varchar)
  return clob is
     my_clob         clob;
     my_bfile        bfile;
     my_dest_offset  integer := 1;
     my_src_offset   integer := 1;
     my_lang_context integer := dbms_lob.default_lang_ctx;
     my_warning      integer;
  begin
     my_bfile := bfilename(directory, file_name);

     dbms_lob.CreateTemporary(my_clob, FALSE, dbms_lob.CALL);
     dbms_lob.FileOpen(my_bfile);
     dbms_output.put_line('get_tracefile: before LoadClobFromFile');

     dbms_lob.LoadClobFromFile (
       dest_lob     => my_clob,
       src_bfile    => my_bfile,
       amount       => dbms_lob.lobmaxsize,
       dest_offset  => my_dest_offset,
       src_offset   => my_src_offset,
       bfile_csid   => dbms_lob.default_csid,
       lang_context => my_lang_context,
       warning      => my_warning
     );
     dbms_output.put_line('get_tracefile warning: ' || my_warning);
     dbms_lob.FileClose(my_bfile);

     return my_clob;
  end get_file;

  function get_tracefile(file_name in varchar)
  return clob is
  begin
    return get_file('UDUMP_DIR',file_name);
  end get_tracefile;

/*
  function get_tracefile(file_name in varchar)
  return clob is
 
        my_clob         clob;
        my_bfile        bfile;
        my_dest_offset  integer := 1;
        my_src_offset   integer := 1;
        my_lang_context integer := dbms_lob.default_lang_ctx;
        my_warning      integer;
  begin
        my_bfile := bfilename('UDUMP_DIR', file_name);

        dbms_lob.CreateTemporary(my_clob, FALSE, dbms_lob.CALL);
        dbms_lob.FileOpen(my_bfile);
        dbms_output.put_line('get_tracefile: before LoadClobFromFile');

        dbms_lob.LoadClobFromFile (
            dest_lob     => my_clob,
            src_bfile    => my_bfile,
            amount       => dbms_lob.lobmaxsize,
            dest_offset  => my_dest_offset,
            src_offset   => my_src_offset,
            bfile_csid   => dbms_lob.default_csid,
            lang_context => my_lang_context,
            warning      => my_warning
        );
        dbms_output.put_line('get_tracefile warning: ' || my_warning);
        dbms_lob.FileClose(my_bfile);

        return my_clob;
    end get_tracefile;
  */

  procedure trace_step(step_name in varchar, job_step_id in number) is
    my_job_step_id varchar(9) := to_char(job_step_id);
    sql_text varchar(255) := 'select ''step_name: ''''' || step_name || 
               ''''' job_log_id: ' || g_job_log.job_log_id || 
              ' job_step_id: ' || my_job_step_id || ''' from dual';
  begin
    execute immediate sql_text;
  end trace_step;

  procedure set_log_level (log_level in pls_integer) is

  begin
    if    log_level < 1 then g_job_log.log_level := 1;
    elsif log_level > 9 then g_job_log.log_level := 9;
    else  g_job_log.log_level := log_level;
    end if;
  end set_log_level;


  PROCEDURE prepare_connection is
        context_info DBMS_SESSION.AppCtxTabTyp;
        info_count   PLS_INTEGER;
        indx         PLS_INTEGER;
  BEGIN
        DBMS_SESSION.LIST_CONTEXT ( context_info, info_count);
        indx := context_info.FIRST;
        LOOP
           EXIT WHEN indx IS NULL;
           DBMS_SESSION.CLEAR_CONTEXT(
               context_info(indx).namespace,
               context_info(indx).attribute,
              null
            );
           indx := context_info.NEXT (indx);
       END LOOP;
       DBMS_SESSION.RESET_PACKAGE;
  END prepare_connection;
    
  procedure logger_dtls_to_str is
        ndx varchar(64);
        dtl logger_dtl%rowtype;
        retval long := '';
  begin
        --  dbms_output.put_line('logger_dtls_to_str');
       -- dbms_output.put_line('about to get first');
       -- ndx := logger_dtls.first();
        -- dbms_output.put_line('ndx "' || ndx || '"');
        
        while ndx is not null loop
            dtl :=  logger_dtls(ndx);
            retval := retval || dtl.logger_nm  || ' ' || dtl.log_lvl || '\n';
            ndx := logger_dtls.next(ndx);
        end loop;
        /*
        if (g_debug ) then
            dbms_output.put_line('>> ' || retval);
        end if;
        */
       -- dbms_output.put_line('end logger_dtls_to_str');
  end logger_dtls_to_str;
    
  function get_log_level (logger_name in varchar) 
  return number 
  is 
        my_logger_name varchar(64) := upper(logger_name);
        my_log_dtl logger_dtl%rowtype;
        retval number;
        was_not varchar(9) := ' was ';
  begin 
         logger_dtls_to_str;
         if (g_debug) then dbms_output.put_line('get_log_level() my_logger_name: "' || my_logger_name || '"'); end if; 
         begin
             my_log_dtl  := logger_dtls(my_logger_name);
             if (g_debug) then dbms_output.put_line('get_log_level() my_dtl_log: "' || my_logger_name || '"'); end if; 
             retval := my_log_dtl.log_lvl;
         exception 
            when no_data_found then
              if g_job_log.log_level is null then
                  retval := g_info;
              else 
                  retval := g_job_log.log_level;
              end if;
              was_not := 'was not';
         end;
        
        if (g_debug) then 
            dbms_output.put_line('get_log_level() ' ||
                ' logger: "'  || logger_name || '" ' ||
                was_not || ' found '  ||
                ' level: '   || to_char(my_log_dtl.log_lvl) || 
                ' retval: ' || to_char(retval));
        end if;
        return retval;
            
  end get_log_level;

  --
  --  Logger hdr and dtl
  --

  procedure create_set (set_nm    in varchar,
                        default_level     in number)
  is
  begin
        insert into logger_hdr (logger_hdr_id, logger_set_nm, default_lvl)
        values (logger_hdr_id_seq.nextval, upper(set_nm), default_level);
  end create_set;

  procedure set_caller_level(name in varchar ,  level in pls_integer)
  is
        dtl  logger_dtl%rowtype;
  begin
	    dtl.logger_nm := upper(name);
	    dtl.log_lvl := level;
	    logger_dtls(dtl.logger_nm) := dtl;
  end;
	    
  procedure define_logger_level(set_nm    in varchar,
                        logger_nm in varchar,
                        level     in number)
  is 
        logger_rec logger_hdr%rowtype;
  begin
      
             insert into logger_dtl (logger_dtl_id, logger_hdr_id, 
                     logger_nm, log_lvl)
             select logger_dtl_id_seq.nextval, 
                    logger_hdr.logger_hdr_id,
                    upper(logger_nm), level
             from   logger_hdr 
             where 
                   logger_set_nm = upper(set_nm);
            
             exception when dup_val_on_index 
             then
                 update logger_dtl 
                 set  log_lvl =  level
                 where logger_hdr_id =  (
                         select logger_hdr_id 
                         from   logger_hdr
                         where logger_set_nm = upper(set_nm) 
			)
                         and logger_nm = upper(logger_nm);
                   
             
             
  end define_logger_level;
   
  procedure log (
      log_msg      in   varchar,
      log_level    in   pls_integer default g_info,
      dumstack   in   boolean default false
  )
  is
      invalid_state_exception exception;
      my_message   varchar2 (32767);
      owner       varchar(64);
      name        varchar(64);
      line        number;
      caller_type varchar(64);
      my_logger_level number;
      my_file_handle utl_file.file_type;
      skip varchar(6) := ' skip ';
  begin
    OWA_UTIL.who_called_me (owner,name,line,caller_type);
    if name is null then
              name := 'anonymous';
    end if;
    my_logger_level := get_log_level(name);
       
    if (g_debug) and log_level > my_logger_level then
            skip := '      ';
            dbms_output.put_line(
              'log() ' ||  skip ||
              'caller: ' || name || 
              ' line: ' || line ||  
              ' my_logger_level: ' || to_char(my_logger_level) ||
               ' log_level: '     || to_char(log_level));
    end if;  

      --dbms_output.put_line('logfile_name: ' || g_job_log.logfile_name);     
      
    if log_level <= my_logger_level then
      if g_job_log.logfile_name is not null then
        -- write to file       
         my_message := logger_message_formatter  (
           job_log_id   => g_job_log.job_log_id,
           job_msg_id   => null,
           log_msg      => log_msg,
           log_level    => log_level,
           caller_name  => name,
           line_number  => line,
           separator    => ',',
           call_stack   => null
         );

         my_file_handle := utl_file.fopen(g_job_log.directory_name,g_job_log.logfile_name,'a'); 
         --my_file_handle := open_log_file (g_job_log.directory_name,g_job_log.logfile_name); 
         UTL_FILE.put_line (my_file_handle, my_message); 
         utl_file.fclose(my_file_handle); 
      else
        raise invalid_state_exception;
        my_message := logger_message_formatter  (
          job_log_id   => g_job_log.job_log_id,
          job_msg_id   => null,
          log_msg      => log_msg,
          log_level    => log_level,
          caller_name  => name,
          line_number  => line,
          separator    => ' ',
          call_stack   => null
          );
          dbms_output.put_line (my_message); 
       end if;
          --
       if (g_debug) then
     	 dbms_output.put_line('log(): ' || my_message); 
       end if;
    end if;
  end log;


begin
   dbms_output.ENABLE(1000000) ;
  -- set_context;
end logger;
/

/*
begin
      sys.DBMS_MONITOR.session_trace_enable(waits=>TRUE, binds=>FALSE);
end;
/
*/
--#<
show errors
--#>
