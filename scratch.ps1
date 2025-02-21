# dbastandard1
$params = @{
	DatabaseLabel = 'dbastandard1'
	App = "lms"
	CellName = "beta"
	ClusterName = "dmstesting"
	Stage = "dev"
	Region = "us-east-1"
	RoleArn = "arn:aws:iam::298171891936:role/dev-platform-api-lms-us-east-1"
}
$created = Add-PostgresDatabaseNonDefaultCluster @params
$created

$endpointParams1 = @{
    D2lInstance        = 'dbastandard1'
    EndpointType       = 'target'
    TargetCluster      = 'dev-beta-dmstesting-postgresqlv2'
    EndpointName       = 'dbastandard1-target-nocsv'
    TargetDatabaseName = 'lms__dbastandard1'
    Split              = 'main'
    UseCSV             = $false
}
Add-Endpoint @endpointParams1

$endpointParams1 = @{
    D2lInstance        = 'dbastandard1'
    EndpointType       = 'target'
    TargetCluster      = 'dev-beta-dmstesting-postgresqlv2'
    EndpointName       = 'dbastandard1-target-csv'
    TargetDatabaseName = 'lms__dbastandard1'
    Split              = 'main'
    UseCSV             = $true
}
Add-Endpoint @endpointParams1

$endpointParams1 = @{
    D2lInstance        = 'dbastandard1'
    EndpointType       = 'source'
    TargetCluster      = 'dev-beta-dmstesting-postgresqlv2'
    EndpointName       = 'dbastandard1-source'
    Split              = 'main'
    UseCSV             = $false
}
Add-Endpoint @endpointParams1

$TableMappingFile = "include-tbls-w-computed-rowver-cols.json"
$taskParams = @{
    D2lInstance         = "dbastandard1"
    SourceEndpointName  = "dbastandard1-source"
    TargetEndpointName  = "dbastandard1-target-nocsv"
    RepInstanceName     = "dba-dms-replinst-1"
    Environment         = "Dev-LMS"
    TableMappingFile    = $TableMappingFile
    MigrationType       = "full-load-and-cdc"
    taskprefix = ""}
.\Add-CustomMigrationTask.ps1 @taskParams

$TableMappingFile = "exclude-tbls-w-compcols.json"
$taskParams = @{
    D2lInstance         = "dbastandard1"
    SourceEndpointName  = "dbastandard1-source"
    TargetEndpointName  = "dbastandard1-target-nocsv"
    RepInstanceName     = "dba-dms-replinst-1"
    Environment         = "Dev-LMS"
    TableMappingFile    = $TableMappingFile
    MigrationType       = "full-load-and-cdc"
    taskprefix = ""}
.\Add-CustomMigrationTask.ps1 @taskParams 

$TableMappingFile = "tbl-news.json"
$taskParams = @{
    D2lInstance         = "dbastandard1"
    SourceEndpointName  = "dbastandard1-source"
    TargetEndpointName  = "dbastandard1-target-csv"
    RepInstanceName     = "dba-dms-replinst-1"
    Environment         = "Dev-LMS"
    TableMappingFile    = $TableMappingFile
    MigrationType       = "full-load"
    taskprefix = ""}
.\Add-CustomMigrationTask.ps1 @taskParams 

$TableMappingFile = "tbl-user-feed-messages.json"
$taskParams = @{
    D2lInstance         = "dbastandard1"
    SourceEndpointName  = "dbastandard1-source"
    TargetEndpointName  = "dbastandard1-target-nocsv"
    RepInstanceName     = "dba-dms-replinst-1"
    Environment         = "Dev-LMS"
    TableMappingFile    = $TableMappingFile
    MigrationType       = "full-load-and-cdc"
    taskprefix = ""}
.\Add-CustomMigrationTask.ps1 @taskParams

# snhudevlms
$endpointParams = @{
    D2lInstance        = 'snhudevlms'
    EndpointType       = 'target'
    TargetCluster      = 'dev-beta-dmstesting-postgresqlv2'
    EndpointName       = 'snhudevlms-target-nocsv'
    TargetDatabaseName = 'lms__snhudevlms'
    Split              = 'main'
    UseCSV             = $false
}
Add-Endpoint @endpointParams

$endpointParams = @{
    D2lInstance        = 'snhudevlms'
    EndpointType       = 'source'
    TargetCluster      = 'dev-beta-dmstesting-postgresqlv2'
    EndpointName       = 'snhudevlms-source'
    Split              = 'main'
    UseCSV             = $false
}
Add-Endpoint @endpointParams


$TableMappingFile = "include-tbls-w-computed-rowver-cols.json"
$taskParams = @{
    D2lInstance         = "snhudevlms"
    SourceEndpointName  = "snhudevlms-source"
    TargetEndpointName  = "snhudevlms-target-nocsv"
    RepInstanceName     = "dba-dms-replinst-1"
    Environment         = "Dev-LMS"
    TableMappingFile    = $TableMappingFile
    MigrationType       = "full-load"
    taskprefix = ""}
.\Add-CustomMigrationTask.ps1 @taskParams

$TableMappingFile = "exclude-tbls-w-computed-rowver-cols.json"
$taskParams = @{
    D2lInstance         = "snhudevlms"
    SourceEndpointName  = "snhudevlms-source"
    TargetEndpointName  = "snhudevlms-target-csv"
    RepInstanceName     = "dba-dms-replinst-1"
    Environment         = "Dev-LMS"
    TableMappingFile    = $TableMappingFile
    MigrationType       = "full-load"
    taskprefix = ""}
.\Add-CustomMigrationTask.ps1 @taskParams 

#tbl-org-users-w-boundaries.json

$TableMappingFile = "tbl-org-users-w-boundaries.json"
$taskParams = @{
    D2lInstance         = "snhudevlms"
    SourceEndpointName  = "snhudevlms-source"
    TargetEndpointName  = "snhudevlms-target-csv"
    RepInstanceName     = "dba-dms-replinst-1"
    Environment         = "Dev-LMS"
    TableMappingFile    = $TableMappingFile
    MigrationType       = "full-load"
    taskprefix = ""}
.\Add-CustomMigrationTask.ps1 @taskParams

