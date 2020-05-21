# dblogging 

## TODO

* prepare connection
* create sets
* job logging

## Overview

The **logger** package provides an easy way to write log messages via *dbms_output* or to a file on 
the database server via *utl_file*.

Messages are assigned a *log_level* and filtering out messages by level and package/function/procedure.

### Log to dbms_output

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
4 "2020-05-17T12:15:20.027262000" "a message" "anonymous" 2   ""                
```

* Log level
* timestamp
* package/function/procedure name from which invoked
* line number of package/function/procedure
* job_log_id (If job tracking, see TODO)
* job_mst_id (If job tracking, see TODO)
* call stack 

### Log to file

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

```


# Narrative 

using a java logging framework or wrapper, such as slf,

This however fails to capture any information essential to end-to-end 
monitoring as it omits what is generally the biggest source of latency, 
the relational database.   

What statements are being executed,
how long do they take, which statements take up the bulk of the resources 
in aggregate (an under-performing statement invoked thousands of times an hour 
is not uncommon).

Oracle provides, at great expense, the ASH subsystem and even that does 
not associated the sql statements to the application code.

This utility provides a simple Application Program Interface to allow you to 
record performance information in a simple, low overhead fashion from any 
java program or any program that allows pl/sql calls.

Thus a few judicious additions to an Oracle Form or a batch job can 
provide the foundation of information necessary to establish where 
database resources are being consumed.

Resolution of these matters is a different matter and may involve gathering statistics, 
altering execution plans, creating or eliminating indexes or rewriting SQL.  

SGA parameters may have to be changed.



# Job Logging

Record jobs and their steps, how long each step took to execute and 
optionally extremely detailed information about every database operation 
as an oracle trace file may be parsed and stored in the 
log repository.

The log repository may be on the same oracle database server, even the same schema 
using the same connection as it uses autonomous transactions, or in postgresql or h2.

# Oracle trace information

The third type of logging is an extension of database logging and stores 
oracle trace information a relational database.

Oracle tracing is turned on and the trace files parsed and aggregated and 
stored in tables associated with the various job steps.  

* oracle
* h2
* postgresql




## Database logs

We will start with an example program and show what is logged.

### Java Example

.. code-block:: java

    package org.javautil.dblogging;
    
    import java.sql.Connection;
    import java.sql.SQLException;
    
    import org.javautil.core.sql.Binds;
    import org.javautil.core.sql.ConnectionUtil;
    import org.javautil.core.sql.SqlStatement;
    import org.javautil.dblogging.logger.Dblogger;
    import org.javautil.util.NameValue;
    import org.slf4j.Logger;
    import org.slf4j.LoggerFactory;
    
    public class DbloggerForOracleExample {
    
    	private Dblogger dblogger;
    	private Connection connection;
    	private String processName;
    	private boolean testAbort = false;
    	private int traceLevel;
    	private final Logger logger = LoggerFactory.getLogger(getClass());
    
    	public DbloggerForOracleExample(Connection connection, Dblogger dblogger, String processName, boolean testAbort,
    			int traceLevel) {
    		this.connection = connection;
    		this.dblogger = dblogger;
    		this.processName = processName;
    		this.testAbort = testAbort;
    		this.traceLevel = traceLevel;
    	}
    
    	public long process() throws SQLException {
    		dblogger.prepareConnection();
    		long id = 0;
    
    		try {
    			id = dblogger.startJobLogging(processName, getClass().getName(), "ExampleLogging", null, 12);
    			logger.debug("============================jobId: {}", id);
    			limitedFullJoin();
    			fullJoin();
    			userTablesCount();
    			if (testAbort) {
    				int x = 1 / 0;
    			}
    			logger.debug("calling endJob");
    			dblogger.endJob();
    		} catch (Exception e) {
    			logger.error(e.getMessage());
    			e.printStackTrace();
    			dblogger.abortJob(e);
    			throw e;
    		}
    		return id;
    	}
    
    	/**
    	 * This will set the v$session.action
    	 */
    	private void limitedFullJoin() throws SQLException {
    		logger.debug("limitedFullJoin =============");
    		dblogger.setAction("actionNoStep");
    		ConnectionUtil.exhaustQuery(connection, "select * from user_tab_columns, user_tables where rownum < 200");
    		dblogger.setAction(null);  // no longer performing that action, so clear 
    		logger.debug("limitedFullJoin complete =============");
    	}
    
    	private void fullJoin() throws SQLException {
    		logger.debug("fullJoinBegins =============");
    		// TODO insertStep should set the action 
    		dblogger.insertStep("fullJoin", "fullJoin", getClass().getName());
    		ConnectionUtil.exhaustQuery(connection, "select * from user_tab_columns, user_tables");
    		dblogger.finishStep();
    		logger.debug("fullJoin complete =============");
    	}
    
    	private void userTablesCount() throws SQLException {
    		dblogger.insertStep("count full", "userTablesCount", getClass().getName());
    		ConnectionUtil.exhaustQuery(connection, "select count(*) dracula from user_tables");
    		dblogger.finishStep();
    		// TODO support implicit finish step
    	}
    
    	NameValue getJobLog(Connection connection, long id) throws SQLException {
    		final String sql = "select * from job_log " + "where job_log_id = :job_stat_id";
    		final SqlStatement ss = new SqlStatement(connection, sql);
    		Binds binds = new Binds();
    		binds.put("job_stat_id", id);
    		final NameValue retval = ss.getNameValue();
    		ss.close();
    		return retval;
    	}
    }

# Tables
## job_tables

In the interest of expediency we have a quick listing of the job tables.

### job_log
     Name                                      Null?    Type
     ----------------------------------------- -------- ----------------------------
     JOB_LOG_ID                                NOT NULL NUMBER(9)
     SCHEMA_NAME                                        VARCHAR2(30)
     PROCESS_NAME                                       VARCHAR2(128)
     THREAD_NAME                                        VARCHAR2(128)
     STATUS_MSG                                         VARCHAR2(256)
     STATUS_TS                                          TIMESTAMP(9)
     END_TS                                             TIMESTAMP(9)
     ELAPSED_MILLIS                                     NUMBER(9)
     SID                                                NUMBER
     SERIAL_NBR                                         NUMBER
     IGNORE_FLG                                         VARCHAR2(1)
     MODULE_NAME                                        VARCHAR2(64)
     CLASSNAME                                          VARCHAR2(255)
     TRACEFILE_NAME                                     VARCHAR2(4000)
     TRACEFILE_DATA                                     CLOB
     TRACEFILE_JSON                                     CLOB
     ABORT_STACKTRACE                                   CLOB
   
### job_step 
     Name                                      Null?    Type
     ----------------------------------------- -------- ----------------------------
     JOB_STEP_ID                               NOT NULL NUMBER(9)
     JOB_LOG_ID                                         NUMBER(9)
     STEP_NAME                                          VARCHAR2(64)
     CLASSNAME                                          VARCHAR2(256)
     STEP_INFO                                          VARCHAR2(2000)
     START_TS                                           TIMESTAMP(9)
     END_TS                                             TIMESTAMP(9)
     DBSTATS                                            CLOB
     STEP_INFO_JSON                                     CLOB
     CURSOR_INFO_RUN_ID                                 NUMBER(9)
     STACKTRACE                                         VARCHAR2(4000)
   
### job_msg 
     Name                                      Null?    Type
     ----------------------------------------- -------- ----------------------------
     JOB_MSG_ID                                         NUMBER(9)
     JOB_LOG_ID                                NOT NULL NUMBER(9)
     LOG_MSG_ID                                         VARCHAR2(8)
     LOG_MSG                                            VARCHAR2(256)
     LOG_MSG_CLOB                                       CLOB
     LOG_MSG_TS                                         TIMESTAMP(9)
     ELAPSED_TIME_MILLISECONDS                          NUMBER(9)
     LOG_SEQ_NBR                               NOT NULL NUMBER(18)
     CALLER_NAME                                        VARCHAR2(100)
     LINE_NBR                                           NUMBER(5)
     CALL_STACK                                         CLOB
     LOG_LEVEL                                          NUMBER(2)

An ERD is near the end of this document.

TODO run the python with the comments     

Each job has one job_log entry and one or more job_steps.

Job steps may have associated log messages.

### Analyzing the logs

Separate utilities are used to analyzed the logs. A very useful tool is 
javautil-condition-identification.

Did any job abort?

What is the trend on elapsed times? 

How do elapsed times vary based on time of day?

Getting deeper, with trace information one can drill down to the details, we will
cover that later.

## Tracefile generation and persistence

This utility provides the information to the Oracle Performance specialist to identify the root cause of the problem, how to repair is another speciality.


# Installation of database artifacts for oracle

## Grant permissions to user

1. Edit defines.sql
 
It should be self explanatory

*  sqlplus sys as sysdba@servicename @ create_user

## Create the tables and package

   sqlplus user/passwor@servicename @ INSTALL

These files may be found under *ddl*

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


## Job Logging

Logging information may be written to a text file, stored in a  database and written to the oracle trace file.

     
## Installation

### Repositories

RDBMS persistence support is provided for Oracle, H2 and postgresql 

H2 is a lightweight database and may be used to eliminate the need for support of another Oracle Database.

Postgresql is a high end database that requires minimal installation and administration.

You should probable not compound your problem with yet another Oracle install, 
but if your DBA will allow you a schema in your database for
logging, you don't have to learn anything else.

The Oracle database could be the same instance as the application being monitored, 
but this may raise some objections to the application DBA.


### Oracle logging repository

If the logging data is to be persisted in Oracle, the tables must be created and 
some packages created.

#### Job log tables

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

### logging package

The logger package provides the following:

	These primarily set information in the SGA and enable oracle session tracing.

begin_java_java

#### change v$session information

procedure prepare_connection;

set_module
set action

## Trace Repository


#### Oracle performance tables

* cursor_explain_plan 
* cursor_sql_text 
* cursor_info_run
* cursor_info 
* cursor_stat 

## logger_persistence package

The logger persistence package provides an API for writing to various tables using 
autonomous transactions.



### Install Oracle JDBC

[See this post](https://blogs.oracle.com/dev2dev/get-oracle-jdbc-drivers-and-ucp-from-oracle-maven-repository-without-ides) to use Oracle JDBC properly. Or, you could download the JAR file, and then execute this command:

TODO the script to locatge 
`mvn install:install-file -DgroupId=com.oracle -DartifactId=oracle-jdbc8 -Dversion=12c -Dpackaging=jar -Dfile=<THE_JDBC_JAR_LOCATION>`

Notations in job .sql script used by sqlrunner.

# Security in production

# User priviliges

# Performance

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

## Metrics

try {
:   String e2eMetrics[] = new
    String[OracleConnection.END\_TO\_END\_STATE\_INDEX\_MAX];
    e2eMetrics[OracleConnection.END\_TO\_END\_ACTION\_INDEX] = null;
    e2eMetrics[OracleConnection.END\_TO\_END\_MODULE\_INDEX] = null;
    e2eMetrics[OracleConnection.END\_TO\_END\_CLIENTID\_INDEX] = null;
    ((OracleConnection) conn).setEndToEndMetrics(e2eMetrics,
    Short.MIN\_VALUE);

} catch (SQLException sqle) {
:   // Do something...

}

0 - No trace. Like switching sql\_trace off. 2 - The equivalent of
regular sql\_trace. 4 - The same as 2, but with the addition of bind
variable values. 8 - The same as 2, but with the addition of wait
events. 12 - The same as 2, but with both bind variable values and wait
events.

Monitoring long running
<https://oracle-base.com/articles/11g/real-time-sql-monitoring-11gr1>

## References

<https://oracle-base.com/articles/misc/dbms_session>

<https://oracle-base.com/articles/misc/sql-trace-10046-trcsess-and-tkprof>


![logger_tables.png](logger_tables.png)


#Spring Developers

Oracle tracing is a powerful tool that logs detailed information about all calls
to the Oracle database.

In order to use this :

* one must turn on tracing for the current connection
* set the log file
* stop tracing
* call a service to store the trace

* store the raw trace file
* analyze the trace file
* store the analyzed trace file

## Logging to flat files 

### Overview

Logs messages using utl_file to a directory on the database server specified.

First the database directory is created and oracle is granted permission to read and
write it, then the ddl "create directory...." and "grant read, write on directory..."


### Examples

#### log_to_file_only.proc.sr.sql

### Input

    set serveroutput on
    set echo on
    create or replace procedure log_to_file_only is 
           long_msg clob := 'this is an absurdly long message, ' || 
                    ' interesting stuff to say so I will just write meaningless ' ||
                    ' stuff for a little while. ' ||
                    ' The quick brown fox jumped over the lazy dog. '; 
        
        my_log_file_name varchar(4096); 
    begin
        my_log_file_name := pllogger.open_log_file('log_to_file_only.text');
        pllogger.set_filter_level(9); -- all messages should go to log file
        pllogger.info('anonymous',$$PLSQL_LINE,'begin loop');
        pllogger.info($$PLSQL_UNIT,$$PLSQL_LINE,long_msg); 
        for i in 1..3  
        loop
            pllogger.fine($$PLSQL_UNIT,$$PLSQL_LINE,'i is ' || to_char(i));
        end loop; 
        pllogger.close_log_file();
    exception when others then
            -- a severe condition is not necessarily fatal
        pllogger.severe($$PLSQL_UINIT,$$PLSQL_LINE,sqlerrm);
        pllogger.close_log_file();
        raise;
    end;
    /
    show errors
    
    exec log_to_file_only();

##### Output 

    "log_level","job_log_id","job_msg_id","line_number","timestamp","log_msg","caller_name","call_stack"
    4,,,17,"2019-10-26T17:19:52.885607","begin loop","anonymous",""
    4,,,18,"2019-10-26T17:19:52.886020","this is an absurdly long message,  exceeding the length of the log_msg field  this should be inserted into the log_msg_clob column.   This message is part of  a unit test of from sample_job_02 of the logging package.   I am running out of  interesting stuff to say so I will just write meaningless  stuff for a little while.  The quick brown fox jumped over the lazy dog. ","LOG_TO_FILE_ONLY",""
    7,,,22,"2019-10-26T17:19:52.886197","i is 1","LOG_TO_FILE_ONLY",""
    7,,,22,"2019-10-26T17:19:52.886357","i is 2","LOG_TO_FILE_ONLY",""
    7,,,22,"2019-10-26T17:19:52.886502","i is 3","LOG_TO_FILE_ONLY",""

# TODO 
Tracing should do the following

* Begin with any transaction as annotated by @Transactional

#  Install 


    cd src/main/resources/ddl/oracle
    
    sqlplus $ORACLE_UID @ pllogger.pkgs.sr.sql
    sqlplus $ORACLE_UID @ pllogger.pkgb.sr.sql

   create directory job_msg_dir as '/common/scratch/ut_process_log_dir';
   grant write on directory to sr;
 
   should be granted by user, not by role.


* Configuring to use your database 
* Example schema

# TODO 
* security can't specify file name 
* need an agent to get the log files for remote users
* TODO escape double quotes in text fields 
* check for anomolous run-times using condition identification
* plot runtimes
* TODO describe microservices, multiple connections, tying them all together
* TODO describe using with spring 

