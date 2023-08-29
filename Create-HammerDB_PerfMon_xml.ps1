<#
For FCI
Create-HammerDB_PerfMon_xml.ps1 -Server "LAB1APSQLA499" -SqlInstanceName "INSTA" -Folder "c:\Perfmon" -DurationInMinutes 10
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

$TimeInSec = $DurationInMinutes*60


    $ConfigTemp = Get-Content $Folder\Hammerdb_Perfmon_template.xml -Raw
    $CustomConfig = $ExecutionContext.InvokeCommand.ExpandString($ConfigTemp)
    $CustomConfig | Out-File $Folder\Hammerdb_Perfmon_$Server.xml

    Notepad $Folder\Hammerdb_Perfmon_$Server.xml
    

