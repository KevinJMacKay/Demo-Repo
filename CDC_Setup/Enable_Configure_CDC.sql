
--For tables without primary keys, set up MS-CDC for the database. 
--Otherwise only Inserts, Deletes amd DDL operations will replicate.
--To do so, use an account that has the sysadmin role assigned to it, and run the following command.
use [lrn-km-db1]
EXEC sys.sp_cdc_enable_db

--Next, set up MS-CDC for each of the source tables. 
--For each table with unique keys but no primary key, 
--run the following query to set up MS-CDC.
exec sys.sp_cdc_enable_table
@source_schema = N'dbo',
@source_name = N'Persons2',
@index_name = N'UC_Person',
@role_name = NULL,
@supports_net_changes = 1
GO

--For each table with no primary key or no unique keys, 
--run the following query to set up MS-CDC.
exec sys.sp_cdc_enable_table
@capture_instance = 'test',
@source_schema = N'dbo',
@source_name = N'Persons2',
@role_name = NULL
GO

--check what tables are setup with cdc
EXECUTE sys.sp_cdc_help_change_data_capture;
GO
--to remove cdc config
EXECUTE sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name = N'Persons2',
    @capture_instance = N'test';