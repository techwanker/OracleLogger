::

    spool create_db 
    @ defines   
    set echo on

    # drop container  
    alter pluggable database &&container close immediate;
    drop pluggable database &&container including datafiles;

    # create container 
    CREATE PLUGGABLE DATABASE &&container 
      ADMIN USER &&username IDENTIFIED BY &&password
      STORAGE (MAXSIZE 8G)
      DEFAULT TABLESPACE &&tablespace_name
        DATAFILE '&&pdb_datafile'
           SIZE 512m  AUTOEXTEND ON
      FILE_NAME_CONVERT = ('/pdbseed/', '/&&container/');

    alter pluggable database &&container open;
    alter pluggable database &&container save state;

    create tablespace &&tablespace_name datafile '&&tablespace_datafile' size &&datafile_size;

    alter session set container = &&container;
    # Validate
    select tablespace_name from dba_tablespaces;

    SELECT tablespace_name
    FROM   dba_tablespaces
    ORDER BY tablespace_name;

    SELECT property_value
    FROM   database_properties
    WHERE  property_name = 'DEFAULT_PERMANENT_TABLESPACE';

    SELECT property_value
    FROM   database_properties
    WHERE  property_name = 'DEFAULT_PERMANENT_TABLESPACE'; 

    create directory scratch as '&&scratch_directory';

