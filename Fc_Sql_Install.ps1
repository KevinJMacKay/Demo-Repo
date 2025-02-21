<#
Install FCI
.\FC_SQL_Install.ps1 `
-FC_NetworkName FCIA01A `
-FC_Instance_Name INSTA `
-FC_IPAddress_Primary "172.19.13.15" `
-FC_Network_Primary "Cluster Network 2" `
-FC_Instance_Data_Disk "FCIA01A-DATA-E" `
-FC_Instance_Log_Disk "FCIA01A-LOG-F" `
-FC_Instance_Sys_Disk "FCIA01A-SYS-T" `
-FC_SQL_Install_Dir "T:" `
-FC_SQL_Backups_Dir "E:\SQL_Backups" `
-FC_SQL_Data_Dir "E:\SQL_Data" `
-FC_SQL_Logs_Dir "F:\SQL_Logs" `
-FC_Tempdb_Dir "Y:\Tempdb" `
-Edition Standard `
-FC_Install

Add Node
.\FC_SQL_Install.ps1 `
-FC_NetworkName FCIA01A `
-FC_Instance_Name INSTA `
-FC_IPAddress_Primary "172.19.13.15" `
-FC_Network_Primary "Cluster Network 2" `
-FC_IPAddress_Secondary "172.19.12.21" `
-FC_Network_Secondary "Cluster Network 1" `
-Edition Standard `
-FC_AddNode
 #>


 param (
    [parameter(Mandatory = $true)][string]$FC_NetworkName,
    [parameter(Mandatory = $true)][string]$FC_Instance_Name,
    [parameter(Mandatory = $true)][string]$FC_IPAddress_Primary,
    [parameter(Mandatory = $true)][string]$FC_Network_Primary,
    [parameter(Mandatory = $false)][string]$FC_IPAddress_Secondary,
    [parameter(Mandatory = $false)][string]$FC_Network_Secondary,
    [parameter(Mandatory = $false)][string]$FC_Instance_Data_Disk,
    [parameter(Mandatory = $false)][string]$FC_Instance_Log_Disk,
    [parameter(Mandatory = $false)][string]$FC_Instance_Sys_Disk,
    [parameter(Mandatory = $false)][string]$FC_Sql_Install_Dir,
    [parameter(Mandatory = $false)][string]$FC_Sql_Backups_Dir,
    [parameter(Mandatory = $false)][string]$FC_Sql_Data_Dir,
    [parameter(Mandatory = $false)][string]$FC_Sql_Logs_Dir,
    [parameter(Mandatory = $false)][string]$FC_Tempdb_Dir,
    [parameter(Mandatory = $false)][string]$Edition,
    [parameter(Mandatory = $false)][string]$MajSqlVer,
    [parameter(Mandatory = $false)][string]$MinSqlVer,
    [parameter(Mandatory = $false)][switch]$FC_Install,
    [parameter(Mandatory = $false)][switch]$FC_AddNode
)

if ((Test-Path C:\Modules\Sql_Admin.psm1) -eq $false) {
    Write-Host "Sql_Admin.psm1 not found."
    exit
}
Import-Module C:\Modules\Sql_Admin.psm1 -Force

$SqlInfoJson = Get-SqlInfo
$Environment = Get-Environment
$Sql_Agent_User = $SqlInfoJson.DataCenters.Aws.$Environment.Sql_Agent_User
$Sql_Engine_User = $SqlInfoJson.DataCenters.Aws.$Environment.Sql_Engine_User
$Packages = $SqlInfoJson.DataCenters.Aws.Packages

if (!$MajSqlVer) {
    $MajSqlVer = $SqlInfoJson.DataCenters.Aws.$Environment.MajSqlVer
}
if (!$MinSqlVer) {
    $MinSqlVer = $SqlInfoJson.DataCenters.Aws.$Environment.MinSqlVer
}

Write-Host "SQL Version and Edition"
Write-Host "Major SQL Version: $MajSqlVer"
Write-Host "Edition: $Edition"
Write-Host "Minor SQL Version: $MinSqlVer"

$WindowsVersion = (Get-CimInstance win32_operatingsystem).caption
if ($WindowsVersion -like "*2019*") {
    Write-Host "Activating Windows 2019....."
    C:\windows\system32\cscript.exe C:\windows\system32\slmgr.vbs -ipk WMDGN-G9PQG-XVVXX-R3X43-63DFG
    if ($Environment -ne "Dev-LMS") {
        C:\windows\system32\cscript.exe C:\windows\system32\slmgr.vbs -skms 172.18.51.227:1688
    } else {
        C:\windows\system32\cscript.exe C:\windows\system32\slmgr.vbs -skms 172.19.18.194:1688
    }
    C:\windows\system32\cscript.exe C:\windows\system32\slmgr.vbs -ato
} else {
    Write-Warning "OS Version not found. Unable to activate Windows"
}

$BaseFolder = "C:\DBA_Scripts\Setup_Scripts"
$FolderName = "$BaseFolder\SQL_Updates\"
Write-Host "Create folder $FolderName and copy lateest CU: ($MinSqlVer) for SQL $MajSqlVer"
if (Test-Path $FolderName) {
    Write-Host "Folder exists: $FolderName"
} else {
    New-Item $FolderName -ItemType Directory
}
$KeyPrefix = "dba-ISO/Updates/$MajSqlVer/$MinSqlVer"
$LocalFolder = "$BaseFolder\SQL_Updates"
Copy-S3Object -BucketName $packages -KeyPrefix $KeyPrefix -LocalFolder $LocalFolder -Force -Region us-east-1

$SqlParamStore = ( Get-SSMParameter -Name dba_sql_server_install -WithDecryption $true ).Value
$SqlParamStore = ConvertFrom-Json $SqlParamStore
$Sql_Agent_Password = $SqlParamStore.Sql_Agent_Password
$Sql_Engine_Password = $SqlParamStore.Sql_Engine_Password
$Sql_SA_Password = $SqlParamStore.Sql_SA_Password
$FtSvcAccount = "NT Service\MSSQLFDLauncher`$$FC_Instance_Name"

If ($FC_Install) {
    $ConfigTemp = Get-Content $BaseFolder\ConfigurationFiles\$MajSqlVer\FCI_Install_template.ini -Raw
    $CustomConfig = $ExecutionContext.InvokeCommand.ExpandString($ConfigTemp)
    $CustomConfig | Out-File $BaseFolder\ConfigurationFiles\Temp\FCI_Install.ini
    $ConfigFile = "$BaseFolder\ConfigurationFiles\Temp\FCI_Install.ini"
}

If ($FC_AddNode) {
    $ConfigTemp = Get-Content $BaseFolder\ConfigurationFiles\$MajSqlVer\FCI_AddNode_template.ini -Raw
    $CustomConfig = $ExecutionContext.InvokeCommand.ExpandString($ConfigTemp)
    $CustomConfig | Out-File $BaseFolder\ConfigurationFiles\Temp\FCI_AddNode.ini
    $ConfigFile = "$BaseFolder\ConfigurationFiles\Temp\FCI_AddNode.ini"
}
Invoke-Expression "$BaseFolder\$MajSqlVer\$Edition\setup.exe /CONFIGURATIONFILE=$ConfigFile"

Write-Host "Delete config file"
Remove-Item $BaseFolder\ConfigurationFiles\Temp\FCI_* -Force
