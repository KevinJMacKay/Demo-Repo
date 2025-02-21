<#
.SYNOPSIS
Imports data from CSV files into SQL Server tables and performs data cleanup.

.DESCRIPTION
This script imports data from CSV files into SQL Server tables specified in the $CsvFiles array.
It then performs data cleanup by deleting rows from the 'SctReportImport' table where the 'Category' column contains specific keywords.

.PARAMETER Database
Specifies the name of the SQL Server database to connect to. Default value is 'SQL_Trace'.

.PARAMETER Server
Specifies the name of the SQL Server instance to connect to. Default value is 'LAB1APSQLL301'.

.EXAMPLE
.\SCT_report_Import.ps1 -Database 'MyDatabase' -Server 'MyServer'
Imports data from CSV files into SQL Server tables and performs data cleanup in the specified database and server.

#>

# Define your database connection details
param(
    [string]$ReportServer = 'LAB1APSQLL301',
    [string]$ReportDatabase = 'SQL_Trace',
    [string]$SourceServer = 'LAB1APSQLL402',
    [string]$SourceDatabase = 'dbatest2'  
)

# Import the SQL Server module
Import-Module SqlServer

# Define your CSV file
$CsvFiles = @(
    [PSCustomObject]@{
        Path      = 'C:\temp\convert\dbatest2\Main\dbatest2.dbo\AURORA_POSTGRESQL_14\dbatest2.dbo-AURORA_POSTGRESQL_14-Csv-report.csv'
        TableName = 'Sct_Report'
    },
    [PSCustomObject]@{
        Path      = 'C:\temp\convert\dbatest2\Main\dbatest2.dbo\AURORA_POSTGRESQL_14\dbatest2.dbo-AURORA_POSTGRESQL_14-Csv-report_Action_Items_Summary.csv'
        TableName = 'Sct_Report_Action_Items_Summary'
    },
    [PSCustomObject]@{
        Path      = 'C:\temp\convert\dbatest2\Main\dbatest2.dbo\AURORA_POSTGRESQL_14\dbatest2.dbo-AURORA_POSTGRESQL_14-Csv-report_Summary.csv'
        TableName = 'Sct_Report_Summary'
    },    
    [PSCustomObject]@{
        Path      = 'C:\temp\convert\dbatest2\Aggregated_report.csv'
        TableName = 'Sct_Aggregated_Report'
    }
)

# Load the data from the CSV files
foreach ($CsvFile in $CsvFiles) {
    $Data = Import-Csv -Path $CsvFile.Path

    # Import the data into the SQL Server table
    $Params = @{
        ServerInstance = $ReportServer
        DatabaseName   = $ReportDatabase
        SchemaName     = 'dbo'
        TableName      = $CsvFile.TableName
        Force          = $true
        InputData      = $Data
    }
    Write-SqlTableData @Params
}

# Data Cleanup
$CleanupQuery = @"
DELETE FROM [Sct_Report_Summary]
WHERE Category LIKE '%Microsoft%'
    OR Category LIKE '%Windows%'
    OR Category LIKE '%sensitivity%'
"@

Invoke-Sqlcmd -ServerInstance $ReportServer -Database $ReportDatabase -Query $CleanupQuery

# Get Build Version
$GetVersion = "SELECT [Version] FROM PRODUCT_VERSION WHERE [Key] = 'Current'"
$BuildVersion = Invoke-Sqlcmd -ServerInstance $SourceServer -Database $SourceDatabase -Query $GetVersion
$BuildVersion = $BuildVersion.Version

# Update Build Version
$UpdateBuildVersion = "
UPDATE [SQL_Trace].[dbo].[Sct_Aggregated_Report]
    SET [BuildVersion] = '$BuildVersion'
 WHERE [BuildVersion] is null

 UPDATE [SQL_Trace].[dbo].[Sct_Report]
   SET [BuildVersion] = '$BuildVersion'
 WHERE [BuildVersion] is null

 UPDATE [SQL_Trace].[dbo].[Sct_Report_Action_Items_Summary]
   SET [BuildVersion] = '$BuildVersion'
 WHERE [BuildVersion] is null

 UPDATE [SQL_Trace].[dbo].[Sct_Report_Summary]
   SET [BuildVersion] = '$BuildVersion'
 WHERE [BuildVersion] is null
"

Invoke-Sqlcmd -ServerInstance $ReportServer -Database $ReportDatabase -Query $UpdateBuildVersion 

