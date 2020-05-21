Logger package
==============

set echo on

::

    create or replace PACKAGE logger AS
        G_SEVERE       CONSTANT PLS_INTEGER := 1 ;
        G_WARNING      CONSTANT PLS_INTEGER := 2 ;
        G_INFO         CONSTANT PLS_INTEGER := 4 ;
        G_SNAP         CONSTANT PLS_INTEGER := 5 ;
        G_ENTERING     CONSTANT PLS_INTEGER := 6 ;
        G_EXITING      CONSTANT PLS_INTEGER := 6 ;
        G_FINE         CONSTANT PLS_INTEGER := 7 ;
        G_FINER        CONSTANT PLS_INTEGER := 8 ;
        G_FINEST       CONSTANT PLS_INTEGER := 9 ;
        G_NONE         CONSTANT PLS_INTEGER := 10 ;

        SEVERE       CONSTANT PLS_INTEGER := 1 ;
        WARNING      CONSTANT PLS_INTEGER := 2 ;
        INFO         CONSTANT PLS_INTEGER := 4 ;
        VERBOSE      CONSTANT PLS_INTEGER := 5 ;
        VERY_VERBOSE CONSTANT PLS_INTEGER := 6 ;
        DEBUG        CONSTANT PLS_INTEGER := 7 ;
        TRACE        CONSTANT PLS_INTEGER := 9 ; 
        NONE         CONSTANT PLS_INTEGER := 10 ;

::

        function format_timestamp(p_timestamp in timestamp) 
        return varchar;

::

        function get_new_job_log_id 
        return number;

Logging
=======

Specify log destination
-----------------------

::

        procedure begin_log ( 
            logfile_name   in varchar,
            logfile_directory in varchar default 'JOB_MSG_DIR',
            p_process_name in varchar default null,
            p_log_set      in varchar default null,
            p_classname    in varchar default null,
            p_module_name  in varchar default null,
            p_status_msg   in varchar default null,
            p_thread_name  in varchar default null,
            log_level    in pls_integer default G_INFO,
            p_trace_level  in pls_integer default G_INFO);

Filter
------

::

        procedure set_caller_level(name in varchar ,  
                                  level in pls_integer);

Log
---

::

        procedure log (
          p_log_msg      in   varchar,
          log_level    in   pls_integer default g_info,
          p_dump_stack   in   boolean default false
       );

job
===

begin\_job
----------

::

       FUNCTION begin_job ( 
            p_process_name in varchar,
            p_log_set      in varchar default null,
            p_classname    in varchar default null,
            p_module_name  in varchar default null,
            p_status_msg   in varchar default null,
            p_thread_name  in varchar default null,
            logfile_name   in varchar default null,
            logfile_directory in varchar default 'JOB_MSG_DIR',
            log_level    in pls_integer default G_INFO,
            p_trace_level  in pls_integer default G_INFO)
            return varchar;

start step
----------

::

       function job_step_insert (
            p_step_name   in varchar, 
            p_step_info   in varchar default null, 
            p_classname   in varchar default null,     
            p_stacktrace  in varchar default null
       ) return number;

finish step
-----------

::

       procedure job_step_finish (step_id in number);

Finish job
----------

::

        procedure end_job;

Abort job
---------

::

        procedure abort_job(exception_msg in varchar default null,
            stacktrace in varchar default null);

TODO
====

::

        procedure set_action (p_action in        varchar) ;

::

        procedure set_module (
            p_module_name in        varchar,
            p_action_name in   varchar
        );

sql trace
=========

::

        function get_tracefile(p_file_name in varchar) 
        return clob;

::

        function get_my_tracefile_name 
        return varchar;

::

        function set_tracefile_identifier(p_job_nbr in number) 
        return varchar;

::

        function get_my_tracefile 
        return clob ;

misc
====

::

        function basename (p_full_path in varchar,
                           p_suffix    in varchar default null,
                           p_separator in char default '/') 
        return varchar;

::

        procedure prepare_connection;

::

        procedure trace_step(p_step_name in varchar, p_job_step_id in number);

::

        function get_directory_path 
        return varchar;

::

        procedure set_debug(debug boolean default true) ;

END logger; / show errors
