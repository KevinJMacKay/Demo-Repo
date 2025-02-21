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
    [string]$ReportServer = 'db-dbatest1',
    [string]$ReportDatabase = 'SCT_Reports',
    [string]$SourceServer = 'db-dbatest2',
    [string]$SourceDatabase = 'dbatest2'
)

# Import the SQL Server module
Import-Module SqlServer

# Define your CSV file
$CsvFiles = @(
    [PSCustomObject]@{
        Path      = 'C:\temp\convert\dbatest2\Aggregated_report.csv'
        TableName = 'Sct_Aggregated_Report'
    },
    [PSCustomObject]@{
        Path      = 'C:\temp\convert\dbatest2-activity\Aggregated_report.csv'
        TableName = 'Sct_Aggregated_Report'
    },
    [PSCustomObject]@{
        Path      = 'C:\temp\convert\dbatest2_lor\Aggregated_report.csv'
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

# Get Build Version
$GetVersion = "SELECT [Version] FROM PRODUCT_VERSION WHERE [Key] = 'Current'"
$BuildVersion = Invoke-Sqlcmd -ServerInstance $SourceServer -Database $SourceDatabase -Query $GetVersion
$BuildVersion = $BuildVersion.Version

# Update Build Version
$UpdateScript = "
 UPDATE [dbo].[Sct_Aggregated_Report]
   SET [BuildVersion] = '$BuildVersion',
         [Schema name] = (SELECT SUBSTRING([Schema name], CHARINDEX('.', [Schema name]) + 1, LEN([Schema name]) - CHARINDEX('.', [Schema name])))
 WHERE [BuildVersion] is null
"

Invoke-Sqlcmd -ServerInstance $ReportServer -Database $ReportDatabase -Query $UpdateScript 

