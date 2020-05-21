Filtering
---------

Each log entry has a log\_level

::

    * SEVERE       CONSTANT PLS_INTEGER := 1 ;
    * WARNING      CONSTANT PLS_INTEGER := 2 ;
    * INFO         CONSTANT PLS_INTEGER := 4 ;
    * VERBOSE      CONSTANT PLS_INTEGER := 5 ;
    * VERY_VERBOSE CONSTANT PLS_INTEGER := 6 ;
    * DEBUG        CONSTANT PLS_INTEGER := 7 ;
    * TRACE        CONSTANT PLS_INTEGER := 9 ; 
    * NONE         CONSTANT PLS_INTEGER := 10 ;

The default logging level is 4.

The default filter level is 4.

The process level default can be changed with the begin\_log with the
*log\_level* parameter:

::

        begin_log(logfile_directory => 'tmp_dir',
                  logfile_name=>'debug.log',
                  log_level=>2);

In which case only messages with log\_level of 2 or less will be logged.

But if it is desired to see more messages from a particular package, the
filter level may changed:
