<#

*********************Run this script on the target server****************
Copy this file and template file (Hammerdb_Perfmon_template.xml) to C:\DBA_Scripts on target server 

For 
.\Create-HammerDB_PerfMon_xml.ps1 -Server LAB1APSQLX466 -Folder C:\DBA_Scripts -DurationInMinutes 5
For FCI
.\Create-HammerDB_PerfMon_xml.ps1 -Server "LAB1APSQLA499" -SqlInstanceName "INSTA" -Folder C:\DBA_Scripts -DurationInMinutes 10
#>

 
param (
    [parameter(Mandatory = $true)][string]$Server,
    [parameter(Mandatory = $false)][string]$SqlInstanceName,
    [parameter(Mandatory = $true)][string]$Folder,
    [parameter(Mandatory = $true)][int]$DurationInMinutes
)

if (!$SqlInstanceName) {
    $SqlInstanceName = "SQLServer"
}
else {
    $SqlInstanceName = "MSSQL`$$SqlInstanceName"
}

$DriveLetters = Get-WmiObject win32_logicaldisk | select -expandproperty caption
$DriveLetters = $DriveLetters.trim(":")
foreach ($Driveletter in $DriveLetters){
$DiskNumber = Get-Partition -DriveLetter $DriveLetter | select -ExpandProperty DiskNumber
$Text1 += "<Counter>\\$Server\PhysicalDisk("+ $DiskNumber.ToString() +" "+ $Driveletter +":)\Disk Reads/sec</Counter>`n"
$Text1 += "<Counter>\\$Server\PhysicalDisk("+ $DiskNumber.ToString() +" "+ $Driveletter +":)\Disk Writes/sec</Counter>`n"
$Text2 += "<CounterDisplayName>\\$Server\PhysicalDisk("+ $DiskNumber.ToString() +" "+ $Driveletter +":)\Disk Reads/sec</CounterDisplayName>`n"
$Text2 += "<CounterDisplayName>\\$Server\PhysicalDisk("+ $DiskNumber.ToString() +" "+ $Driveletter +":)\Disk Writes/sec</CounterDisplayName>`n"
 }

$TimeInSec = $DurationInMinutes * 60

$ConfigTemp = Get-Content $Folder\Hammerdb_Perfmon_template.xml -Raw
$CustomConfig = $ExecutionContext.InvokeCommand.ExpandString($ConfigTemp)
$CustomConfig | Out-File $Folder\Hammerdb_Perfmon_$Server.xml

Notepad $Folder\Hammerdb_Perfmon_$Server.xml
    

