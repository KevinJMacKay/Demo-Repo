#!/bin/tclsh
dbset db mssqls
diset tpcc mssqls_count_ware 250
diset tpcc mssqls_num_vu 100
diset connection mssqls_server {LAB1APSQLP497}
vuset logtotemp 1
print dict
buildschema
waittocomplete