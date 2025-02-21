/*============================================================================
  
  Summary:  Short snapshot of wait stats --Step 1

============================================================================*/
USE [Master]
  IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'Stats')
  BEGIN
     CREATE DATABASE Stats
	 BACKUP DATABASE [Stats] TO  DISK = N'V:\SQL_Backups\Stats_full.bak' 
  END
    GO
 
USE [Stats]
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WaitsOverTime]') AND type in (N'U'))
CREATE TABLE [dbo].[WaitsOverTime](
	[CollectionTime] [datetime] NULL,
	[WaitType] [nvarchar](60) NOT NULL,
	[Wait_S] [decimal](16, 2) NULL,
	[Resource_S] [decimal](16, 2) NULL,
	[Signal_S] [decimal](16, 2) NULL,
	[WaitCount] [bigint] NULL,
	[Percentage] [decimal](5, 2) NULL,
	[AvgWait_S] [decimal](16, 4) NULL,
	[AvgRes_S] [decimal](16, 4) NULL,
	[AvgSig_S] [decimal](16, 4) NULL,
	[Help/Info URL] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
  
IF EXISTS (SELECT * FROM [Stats].[sys].[objects]
    WHERE [name] = N'SQLskillsStats1')
    DROP TABLE [SQLskillsStats1];
  
IF EXISTS (SELECT * FROM [Stats].[sys].[objects]
    WHERE [name] = N'SQLskillsStats2')
    DROP TABLE [SQLskillsStats2];
GO
  
SELECT [wait_type], [waiting_tasks_count], [wait_time_ms],
       [max_wait_time_ms], [signal_wait_time_ms]
INTO SQLskillsStats1
FROM sys.dm_os_wait_stats;
GO