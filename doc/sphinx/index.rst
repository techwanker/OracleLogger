Logger for PL/SQL
=================


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`


Overview
--------

The **logger** package provides an easy way to write log messages via
*dbms\_output* or to a file on the database server via *utl\_file*.

Messages are assigned a *log\_level* and filtering out messages by level
and package/function/procedure.

Log to dbms\_output
~~~~~~~~~~~~~~~~~~~

The call

::

       logger.log('message')
    # Job Logging

    Record jobs and their steps, how long each step took to execute and 
    optionally extremely detailed information about every database operation 
    as an oracle trace file may be parsed and stored in the 
    log repository.

    The log repository may be on the same oracle database server, even the same schema 
    using the same connection as it uses autonomous transactions, or in postgresql or h2.

::

    SQL> set serveroutput on
    SQL> begin
      2     logger.log('a message');
      3  end;
      4  /
    4 "2020-05-17T12:15:20.027262000" "a message" "anonymous" 2   ""                

-  Log level
-  timestamp
-  package/function/procedure name from which invoked
-  line number of package/function/procedure
-  job\_log\_id (If job tracking, see TODO)
-  job\_mst\_id (If job tracking, see TODO)
-  call stack

Log to file
~~~~~~~~~~~

The call

::

      logger.begin_log(logfile_directory => 'TMP_DIR', logfile_name => '02_log_to_file.log');

Will cause subsequent log messages to be written to the filesystem of
the database server.

In order for this to work a database directory must be defined e.g.

::

        create directory tmp_dir as '&&tmp_directory';
        grant read, write on directory tmp_dir to &username;

cat /tmp/02\_log\_to\_file.log

A comma separated values *CSV* file is written to in append mode; if the
file already exists, new records are written to the end.

If multiple processes are writing to the same file it is best to use
**start\_job**, which will write a job identifier to the file.

::

    4,"2020-05-17T12:31:40.092661000","a message","anonymous",3,,,""


.. toctree::
   :maxdepth: 2
   :caption: Contents:

   filter
   example_log_suite
   job_logging
   logger.pks.sr  
   install
