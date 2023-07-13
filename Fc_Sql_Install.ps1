<#
Install FCI
.\FC_Sql_Install.ps1 -FC_NetworkName WSFC4 -FC_Instance_Name INSTD -FC_IPAddress_Primary "172.19.12.7" -FC_Network_Primary "Cluster Network 2" -FC_Instance_Data_Disk "INSTD-DATA" -FC_Instance_Log_Disk "INSTD-LOG" -FC_Sql_Install_Dir "E:\Sql_Data" -FC_Sql_Backups_Dir "E:\Sql_Backups" -FC_Sql_Data_Dir "E:\Sql_Data" -FC_Sql_Logs_Dir "F:\Sql_Logs" -FC_Tempdb_Dir "E:\Tempdb" -Edition Standard -FC_Install

Add Node
 .\FC_Sql_Install.ps1 -FC_NetworkName WSFC4 -FC_Instance_Name INSTD -FC_IPAddress_Primary "172.19.12.7" -FC_Network_Primary "Cluster Network 2" -FC_IPAddress_Secondary "172.19.13.10" -FC_Network_Secondary "Cluster Network 1" -Edition Standard -FC_AddNode
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
    [parameter(Mandatory = $false)][string]$FC_Sql_Install_Dir,
    [parameter(Mandatory = $false)][string]$FC_Sql_Backups_Dir,
    [parameter(Mandatory = $false)][string]$FC_Sql_Data_Dir,
    [parameter(Mandatory = $false)][string]$FC_Sql_Logs_Dir,
    [parameter(Mandatory = $false)][string]$FC_Tempdb_Dir,
    [parameter(Mandatory = $false)][string]$Edition,
    [parameter(Mandatory = $false)][string]$MajorSqlVersion,
    [parameter(Mandatory = $false)][string]$MinorSqlVersion,
    [parameter(Mandatory = $false)][switch]$FC_Install,
    [parameter(Mandatory = $false)][switch]$FC_AddNode
)

if ((Test-Path C:\Modules\Sql_Admin.psm1) -eq $false) {
    Write-Host "Sql_Admin.psm1 not found."
    exit
}
Import-Module C:\Modules\Sql_Admin.psm1 -force

$SqlInfoJson = Get-SqlInfo
$Environment = Get-Environment
$Sql_Agent_User = $SqlInfoJson.DataCenters.Aws.$Environment.Sql_Agent_User
$Sql_Engine_User = $SqlInfoJson.DataCenters.Aws.$Environment.Sql_Engine_User    
$Packages = $SqlInfoJson.DataCenters.Aws.Packages

###Determine Version
if (!$MajorSqlVersion) {
    $MajorSqlVersion = $SqlInfoJson.DataCenters.Aws.$Environment.MajorSqlVersion
}
if (!$MinorSqlVersion) {
    $MinorSqlVersion = $SqlInfoJson.DataCenters.Aws.$Environment.MinorSqlVersion
}
    
write-host "After verification"
write-host "Major SQL Version: $MajorSqlVersion"
write-host "Edition: $Edition"
write-host "Minor SQL Version: $MinorSqlVersion" 

# Activate Windows
$WindowsVersion = (Get-CimInstance win32_operatingsystem).caption
if ($WindowsVersion -like "*2019*") {	
    Write-Host "Activating Windows 2019....."
    C:\windows\system32\cscript.exe C:\windows\system32\slmgr.vbs -ipk WMDGN-G9PQG-XVVXX-R3X43-63DFG
    if ($Environment -ne "Dev-LMS") {
        C:\windows\system32\cscript.exe C:\windows\system32\slmgr.vbs -skms 172.18.51.227:1688
    }
    else {
        C:\windows\system32\cscript.exe C:\windows\system32\slmgr.vbs -skms 172.19.18.194:1688
    }
    C:\windows\system32\cscript.exe C:\windows\system32\slmgr.vbs -ato
}
else {
    Write-Warning "OS Version not found. Unable to activate Windows"
}

# Copy latest CU to C:\DBA_Scripts\Setup_Scripts\SQL_Updates\
$FolderName = "C:\DBA_Scripts\Setup_Scripts\SQL_Updates\"
Write-Host "Create folder $FolderName and copy update ($MinorSqlVersion) for SQL $MajorSqlVersion"
if (Test-Path $FolderName) {
   Write-Host "Folder exists: $FolderName"
}
else{
    New-Item $FolderName -ItemType Directory
}
#Copy-S3Object -BucketName $packages -KeyPrefix dba-ISO/Updates/$MajorSqlVersion/$MinorSqlVersion -LocalFolder C:\DBA_Scripts\Setup_Scripts\SQL_Updates -force -Region us-east-1

# Get service account info from Parameter Store
$SqlParamStore = ( Get-SSMParameter -Name dba_sql_server_install -WithDecryption $true ).Value
$SqlParamStore = ConvertFrom-Json $SqlParamStore
$Sql_Agent_Password = $SqlParamStore.Sql_Agent_Password
$Sql_Engine_Password = $SqlParamStore.Sql_Engine_Password
$Sql_SA_Password = $SqlParamStore.Sql_SA_Password
$FtSvcAccount = "NT Service\MSSQLFDLauncher`$$FC_Instance_Name"

# Update config files and install SQL.
If ($FC_Install) {
    $Configuration = Get-Content C:\DBA_Scripts\Setup_Scripts\ConfigurationFiles\$MajorSqlVersion\ConfigurationFile_FCI_Install_template.ini -Raw
    $CustomConfig = $ExecutionContext.InvokeCommand.ExpandString($Configuration)
    $CustomConfig | Out-File C:\DBA_Scripts\Setup_Scripts\ConfigurationFiles\Temp\ConfigurationFile_FCI_Install.ini

    #Invoke-Expression "C:\DBA_Scripts\Setup_Scripts\$MajorSqlVersion\$Edition\setup.exe /CONFIGURATIONFILE=C:\DBA_Scripts\Setup_Scripts\ConfigurationFiles\Temp\ConfigurationFile_FCI_Install.ini"

}

If ($FC_AddNode) {
    $Configuration = Get-Content C:\DBA_Scripts\Setup_Scripts\ConfigurationFiles\$MajorSqlVersion\ConfigurationFile_FCI_AddNode_template.ini -Raw
    $CustomConfig = $ExecutionContext.InvokeCommand.ExpandString($Configuration)
    $CustomConfig | Out-File C:\DBA_Scripts\Setup_Scripts\ConfigurationFiles\Temp\ConfigurationFile_FCI_AddNode.ini

    #Invoke-Expression "C:\DBA_Scripts\Setup_Scripts\$MajorSqlVersion\$Edition\setup.exe /CONFIGURATIONFILE=C:\DBA_Scripts\Setup_Scripts\ConfigurationFiles\Temp\ConfigurationFile_FCI_AddNode.ini"

}

# Update config files and install SQL.
Write-Host "Delete config file"
Remove-Item C:\DBA_Scripts\Setup_Scripts\ConfigurationFiles\Temp\ConfigurationFile* -force
