param (    
[parameter(Mandatory = $false)][string]$Server,
[parameter(Mandatory = $false)][string]$Instance,	
[parameter(Mandatory = $false)][string]$Database,	
[parameter(Mandatory = $false)][string]$Workload_VUs,	
[parameter(Mandatory = $false)][string]$WorkloadFile,	
[parameter(Mandatory = $false)][string]$LogFile,
[parameter(Mandatory = $false)][string]$Duration,
[parameter(Mandatory = $false)][string]$Results,
[parameter(Mandatory = $false)][string]$RestorePath,
[parameter(Mandatory = $false)][string]$DataPath,
[parameter(Mandatory = $false)][string]$LogPath,
[parameter(Mandatory = $false)][string]$Allwarehouse,
[parameter(Mandatory = $false)][string]$Rampup
)

<#
Usage:
.\Run_Hammerdb.ps1 -Server SQLFCI1 -LogFile 'C:\Users\KMACKA~1\AppData\Local\Temp\hammerdb.log' `
-Duration 2 -Results 'C:\DBA_Scripts\HammerDB\HammerDBResults.txt' -WorkloadFile 'C:\DBA_Scripts\HammerDB\workload.tcl' `
-Database 'Hammerdb_25' -Workload_VUs '25 50 75 100' -RestorePath 'D:\SQL_Backups' -DataPath 'D:\SQL_Data' -LogPath 'F:\SQL_Logs'`
-allwarehouse 'true' -rampup 5
#>

if ($Instance){
$SqlServer = $server +"\"+ $Instance
} else {
	$SqlServer = $server
}

#Check for database on server. Copy and restore if not found.
$Database = $Database.ToLower()
$FindDBQuery = "Select name from sys.databases where name = '$Database'"
$FindDB = invoke-sqlcmd -ServerInstance $SqlServer -query $FindDBQuery 
Write-Host "Checking for database $Database on $Server."			
if ($FindDB) {
    Write-Host "Found database $Database on $SqlServer. Proceeding." -ForegroundColor Green
}
ELSE {
    Write-Host "Database $Database NOT FOUND on $SqlServer" -ForegroundColor Yellow   
    Write-Host "Copying $Database backup from s3 and restoring database from $RestorePath\$Database.bak."
    Invoke-Command -ComputerName $server -scriptblock { param ($Database,$RestorePath,$Server,$SqlServer,$DataPath,$LogPath)
        $Key = "hammerdb/$Database.bak"
        $LocalFile = "$RestorePath\$Database.bak"
        Write-host "Copy-S3Object -BucketName dba-ami-updates -Key $Key -LocalFile "$LocalFile""
        Copy-S3Object -BucketName dba-ami-updates -Key $Key -LocalFile "$LocalFile"
        
		$IsSQLServerModulePresent = Get-Module sqlserver -ListAvailable
		if($IsSQLServerModulePresent) {
			$IsSQLPSLoaded = (Get-Module | Where-Object {$_.Name -eq "sqlps" -and $_.Version -ne "0.0"}).Name
			if($IsSQLPSLoaded) {
				Remove-Module sqlps
			}
			$CurrentPath = Get-Location
			Import-Module sqlserver -Force
			Set-Location $CurrentPath
		}
		else {
			$CurrentPath = Get-Location
			Import-Module sqlps -Force
			Set-Location $CurrentPath
		}	
		
		if(test-path "$RestorePath\$Database.bak"){
            #[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
            #[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
            $DataPathFull = "$DataPath\$Database.mdf"
            $LogPathFull = "$LogPath\$Database"+"_log.ldf"
            $LogicalDataName = $Database
            $LogicalLogName = $Database+"_log"
            Write-Host "Restoring $Database on $SqlServer"
            $RelocateData = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("$LogicalDataName", "$DataPathFull")
            $RelocateLog  = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("$LogicalLogName", "$LogPathFull")
            Restore-SqlDatabase -ServerInstance $SqlServer -Database $Database -BackupFile "$RestorePath\$Database.bak" -RelocateFile @($RelocateData,$RelocateLog) 
        }
    } -ArgumentList $Database,$RestorePath,$Server,$SqlServer,$DataPath,$LogPath
}

#If the file does not exist, create it.
if (Test-Path -Path $LogFile -PathType Leaf) {
     try {
         Remove-Item $LogFile
         Write-Host "Removing [$LogFile]."
     }
     catch {
         throw $_.Exception.Message
     }
 } else {
     Write-Host "File [$LogFile] does not exist."
 }
Write-Host `n"Workload Details:
Server: $SqlServer
Database: $database
Test Duration: $duration
Virtual User(s) per test: $workload_vus
"
Start-sleep 5
# Prepare workload file
$workload_File = $WorkloadFile -replace ".tcl" , "_$server.tcl"
$workload = Get-Content $WorkloadFile
			$workload = $workload -replace "<server>" , $SqlServer
			$workload = $workload -replace "<database>" , $database
			$workload = $workload -replace "<duration>" , $duration
			$workload = $workload -replace "<workload_vus>" , $workload_vus
            $workload = $workload -replace "<allwarehouse>" , $allwarehouse
            $workload = $workload -replace "<rampup>" , $rampup
			$workload | Set-Content $Workload_File

set-Location -path "C:\Program Files\HammerDB-4.4\"
$Location = Get-Location
Write-Host $Location
# Run worload
& "C:\Program Files\HammerDB-4.4\hammerdbcli.bat" auto $Workload_File

# Truncate and shrink Tlogs
$TruncQueryFile = "C:\DBA_Scripts\HammerDB\Hammerdb_backups.sql"
$TruncQuery_File = $TruncQueryFile -replace ".sql" , "_$server.sql"
$TruncQuery = Get-Content $TruncQueryFile
			$TruncQuery = $TruncQuery -replace "<database>" , $database
			$TruncQuery | Set-Content $TruncQuery_File
invoke-sqlcmd -ServerInstance $SqlServer -inputfile $TruncQuery_File | Out-Null

# Parse Hammerdb log
Set-Location "C:\DBA_Scripts\HammerDB"
.\ParseLog_param.ps1 -Server $Server -SqlServer $SqlServer -Database $Database -LogFile $LogFile -Results $Results

notepad.exe $Results