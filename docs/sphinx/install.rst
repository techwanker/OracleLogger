Installation
============

Grant permissions to user
-------------------------

1. Edit defines.sql

It should be self explanatory

-  sqlplus sys as sysdba@servicename @ create\_user

Create the tables and package
-----------------------------

sqlplus user/passwor@servicename @ INSTALL

These files may be found under *ddl*

The script that runs them all is *INSTALL.sql*
