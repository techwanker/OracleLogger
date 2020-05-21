# Logger for PL/SQL

## User documentation 

Additional documentation may be found under:

* docs/sphinx/_build/html/index.html
* docs/sphinx/_build/singlehtml/index.html
* docs/sphinx/_build/latex/loggerforplsql.pdf

## Overview

The **logger** package provides an easy way to write log messages via *dbms_output* or to a file on 
the database server via *utl_file*.

Messages are assigned a *log_level* and filtering out messages by level and package/function/procedure.



## Log to dbms_output

The call

``` 
   logger.log('message')
```


```
SQL> set serveroutput on
SQL> begin
  2  	logger.log('a message');
  3  end;
  4  /
```
results in the following output:

```
4 "2020-05-17T12:15:20.027262000" "a message" "anonymous" 2   ""                
```

The fields (space delimited, quoted strings) are:

* Log level
* timestamp
* package/function/procedure name from which invoked
* line number of package/function/procedure
* job_log_id (If job tracking, see TODO)
* job_mst_id (If job tracking, see TODO)
* call stack 

## Log to file

The call
```
  logger.begin_log(logfile_directory => 'TMP_DIR', logfile_name => '02_log_to_file.log');
```

Will cause subsequent log messages to be written to the filesystem of 
the database server.

In order for this to work a database directory must be defined e.g.

```
    create directory tmp_dir as '&&tmp_directory';
    grant read, write on directory tmp_dir to &username;
```

cat /tmp/02_log_to_file.log

A comma separated values *CSV* file is written to in append mode; if the file 
already exists, new records are written to the end.

If multiple processes are writing to the same file it is best to use **start_job**,
which will write a job identifier to the file.

```
4,"2020-05-17T12:31:40.092661000","a message","anonymous",3,,,""
```

## Filtering

Each log entry has a log_level 

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

The process level default can be changed with the begin_log with the
*log_level* parameter:

```
    begin_log(logfile_directory => 'tmp_dir',logfile_name=>'debug.log',
       log_level=>2);
```

In which case only messages with log_level of 2 or less will be logged.

But if it is desired to see more messages from a partilar package, the filter
level may changed:


# Job Logging

Record jobs and their steps, how long each step took to execute and 
optionally extremely detailed information about every database operation 
as an oracle trace file may be parsed and stored in the 
log repository.

The log repository may be on the same oracle database server, even the same schema 
using the same connection as it uses autonomous transactions, or in postgresql or h2.




# Analyzing the logs

Separate utilities are used to analyzed the logs. A very useful tool is 
javautil-condition-identification.

Did any job abort?

What is the trend on elapsed times? 

How do elapsed times vary based on time of day?

Getting deeper, with trace information one can drill down to the details, we will
cover that later.


# Installation of database artifacts for oracle

These files may be found under *ddl*

## Grant permissions to user

1. Edit defines.sql
 
It should be self explanatory

*  sqlplus sys as sysdba@servicename @ create_user

## Create the tables and package

   sqlplus user/passwor@servicename @ INSTALL


The script that runs them all is *INSTALL.sql*


## prepare_connnection

prepare-connection provides one procedure.   
This will call dbms_session.clear_context for each context variable, 
restoring the context for a connection returned from a connection_pool to
the state the of an initially opened connection.  

Connection pools do not generally clear this information out as it is Oracle specific.

## my_session_info.sql

creates the view *my_session_info* to allow the connected user to obtain the v$session record for the current connection.

## logger_message_formatter

Provides  the *logger_message_formatter* function, which creates a single string from all of the logging 
parameters and makes a call to dbms_output.put_line and then returns the formatted message.



# Database Objects  

## Job log tables

1. job_log
#. job_msg
#. job step

The granularity of job step is left to the invoker.  
As the overhead is very low, there is no reason to
be parsimonious with identification, it's a simple one line call in the user app.  


These records can be reviewed for job success or failure and form a historical basis of time elapsed.

This may be used as a starting pointing in locating "what processes are using the time?"  

Additionally they constitute a base performance metric from which runtime 
degradation or periodic anomalous runs may be identified.

Data is committed by calls from java to the package logger, provided here.

The package creates autonomous commits and hence may be safely called using the same 
connection as the application.

## logger package

### change v$session information

procedure prepare_connection;

set_module
set action

## Trace Repository



# Tools and concepts

User should be familiar with v$ssession view, tkprof command line utility

# Connection Pools

## After Getting a connection

### Contexts

If a session is being used as part of a connection pool and the state of
its contexts are not reinitialized, this can lead to unexpected
behavior.

### Packages

Sessions have the ability to alter package state by amending the
values of package variables. If a session is being used as part of a
connection pool and the state of its packages are not reinitialized,
this can lead to unexpected behavior. To solve this, Oracle provides
the dbms_session.reset_package procedure.

The dbloggging provided procedure clears all context variables and resets package state.

Connections must be reset immediately after being obtained from a
connection pool

In src/main/resources/ddl/oracle/prepare_connection


create public synonym prepare_connection for prepare_connection;
grant execute on prepare_connection to public;
```

### Zaxxer

TODO how to call this procedure in the connection pool

## DBMS\_SESSION
-------------

## Identifier

SET_IDENTIFIER and CLEAR_IDENTIFIER procedures to allow the real user
to be associated with a session, regardless of what database user was
being used for the connection.


