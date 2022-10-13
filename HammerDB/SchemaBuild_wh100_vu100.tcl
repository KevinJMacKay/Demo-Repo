#!/bin/tclsh
dbset db mssqls
diset tpcc mssqls_dbase hammerdb_100
diset tpcc mssqls_count_ware 100
diset tpcc mssqls_num_vu 100
diset connection mssqls_server {SQLFCI1}
vuset logtotemp 1
print dict
buildschema
waittocomplete