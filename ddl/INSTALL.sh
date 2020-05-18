if [ -z $ORACLE_UID ] ; then
   echo export ORACLE_UID=username/password@servicename 2>&1
   return 
fi 

sqlplus / as sysdba @ trace_my_session
sqlplus $ORACLE_UID @ read_file
