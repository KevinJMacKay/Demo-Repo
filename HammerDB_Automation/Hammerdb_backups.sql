--Checkpoint
--dbcc sqlperf(logspace)

--Check for log reuse wait
--select Name,log_reuse_wait_desc from sys.databases where name like '%hammerdb_%'

BACKUP LOG [<database>] TO  DISK='NUL:' 
USE [<database>]
DBCC SHRINKFILE (N'<database>_log' , 1068)

DBCC SQLPERF(LOGSPACE);  
GO   