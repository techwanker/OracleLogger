
Job Logging
===========

Record jobs and their steps, how long each step took to execute and 
optionally extremely detailed information about every database operation 
as an oracle trace file may be parsed and stored in the log repository.

The log repository may be on the same oracle database server, even the same schema 
using the same connection as it uses autonomous transactions, or in postgresql or h2.

Steps may be executed in parallel or sequentially.

Parallel operations are common with modern web frameworks, for example a node.js 
environment making a collection of calls.

The web developer may be interested in the total elapsed wall time while the
architect / DBA may have a strong interest in the aggregate CPU time.

Gathering this information accross separate database connections is left for another project
which requires daemons to run on the database server to process the oracle trace files.

 
