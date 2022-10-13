param (    
	[parameter(Mandatory = $false)][AllowEmptyString()][array]$Server,
	[parameter(Mandatory = $false)][AllowEmptyString()][string]$BackupDrive,
	[parameter(Mandatory = $false)][AllowEmptyString()][string]$s3Bucket
	)

$CurrentDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( ` (Get-Date), 'Eastern Standard Time')
Write-Host `n"###---> Deploying Backup Jobs "$CurrentDate 

$ErrorActionPreference = 'Stop'
# import modules 
Import-Module "$PSScriptRoot\..\..\Modules\SQL_Admin.psm1"
Import-Module "$PSScriptRoot\..\..\Modules\SQL_Install.psm1"

if(!$Server){
	$Server = Get-SQLServers	
}
$Server = $Server.ToUpper()
$Environment = Get-environment
$sqlinfoJson = Get-sqlinfo
$BackupStartTime = $sqlinfoJson.datacenters.aws.$Environment.BackupStartTime
if (!$s3Bucket){
	$s3Bucket = $sqlinfoJson.datacenters.aws.$Environment.SQL_Backups_S3_Bucket
} else {
$s3Bucket = $s3Bucket
}

Add-BackupJobs -Servers $Server -FullStartTime $BackupStartTime -DiffStartTime $BackupStartTime -Drive $BackupDrive -s3Bucket $s3Bucket

Import-Module "$PSScriptRoot\..\..\Modules\SQL_Admin.psm1"
foreach ($SQLServer in $Server) {
	$SQLServer = $SQLServer.Trim()
	Enable-TLOGBackups -SQLServer $SQLServer
}