param (    
[parameter(Mandatory = $false)][string]$Server,	
[parameter(Mandatory = $false)][string]$Database,	
[parameter(Mandatory = $false)][string]$Workload_VUs,	
[parameter(Mandatory = $false)][string]$WorkloadFile,	
[parameter(Mandatory = $false)][string]$LogFile,
[parameter(Mandatory = $false)][string]$Duration,
[parameter(Mandatory = $false)][string]$Results
)

#'C:\Users\KMACKA~1\AppData\Local\Temp\hammerdb.log'
#'C:\DBA_Scripts\HammerDB\workload_25_50x4.tcl'

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

$workload_File = $WorkloadFile -replace ".tcl" , "_$server.tcl"
$workload = Get-Content $WorkloadFile
			$workload = $workload -replace "<server>" , $server
			$workload = $workload -replace "<database>" , $database
			$workload = $workload -replace "<duration>" , $duration
			$workload = $workload -replace "<workload_vus>" , $workload_vus
			$workload | Set-Content $Workload_File

set-Location -path "C:\Program Files\HammerDB-4.4\"
$Location = Get-Location
Write-Host $Location
& "C:\Program Files\HammerDB-4.4\hammerdbcli.bat" auto $Workload_File

Set-Location "C:\DBA_Scripts\HammerDB"
.\ParseLog_param.ps1 -Server $Server -LogFile $LogFile -Results $Results

notepad.exe $Results