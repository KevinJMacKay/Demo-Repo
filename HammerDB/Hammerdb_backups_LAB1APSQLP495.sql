--Checkpoint
--dbcc sqlperf(logspace)

--Check for log reuse wait
--select Name,log_reuse_wait_desc from sys.databases where name like '%hammerdb_%'

BACKUP LOG [hammerdb_25] TO  DISK='NUL:' 
USE [hammerdb_25]
DBCC SHRINKFILE (N'hammerdb_25_log' , 1068)

DBCC SQLPERF(LOGSPACE);  
GO   
