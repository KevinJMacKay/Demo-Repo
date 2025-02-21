--SELECT TOP (1000) [Database]
--      ,[BufferPool_Memory_Usage_in_MB]
--      ,[BufferPool_Memory_Usage_As%]
--      ,[Collection_time]
--  FROM [SQL_Trace].[dbo].[BufferPool_Memory_Monitor]


DECLARE @timeframe DATETIME = '2024-06-11T16:31:12.611Z'
SELECT collection_time,* FROM SQL_Trace.[dbo].[WhoIsActive]
WHERE collection_time between DATEADD(HOUR,-30,@timeframe) and @timeframe
AND wait_info not like '%WAITFOR%' 
AND wait_info not like '%HADR_SYNC_COMMIT%' 
AND wait_info not like '%WRITELOG%' 
AND login_name not in ('NT AUTHORITY\SYSTEM')
AND convert(varchar(max),sql_text) not like '%SELECT @FilePath%'
AND convert(varchar(max),sql_text) not like '%xp_readerrorlog%'
AND convert(varchar(max),sql_text) not like '%BACKUP DATABASE%'
order by 1 desc
