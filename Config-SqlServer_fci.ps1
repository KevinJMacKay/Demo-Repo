<#
    	.Synopsis
		Runs SQL Scripts required to complete setup. Should be run right after SQL Install has been completed.
	#>


param (    
	[parameter(Mandatory = $true)][string]$ServerName,
	[parameter(Mandatory = $true)][string]$SqlInstanceName,
	[parameter(Mandatory = $false)][string]$TempDBDirectory = "Z:\tempdb",
	[parameter(Mandatory = $false)][string]$MinMemory,
	[parameter(Mandatory = $false)][string]$MaxMemory,
	[parameter(Mandatory = $false)][string]$DataDrive = "Z",
	[parameter(Mandatory = $false)][string]$LogDrive = "Z",
	[parameter(Mandatory = $false)][string]$BackupDrive = "Z",
	[parameter(Mandatory = $true)][string]$TaskAdminPassword,
	[parameter(Mandatory = $false)][switch]$WhatIf
)

if ((Test-Path C:\Modules\SQL_Admin.psm1) -eq $false) {
	Write-Host "SQL_Admin.psm1 not found."
	Exit
}

Import-Module C:\Modules\SQL_Admin.psm1 -force
$SqlInfoJson = Get-sqlinfo
$Environment = Get-environment
$Server = "$Servername\$SqlInstanceName"
$TempDBDirectory = $TempDBDirectory.TrimEnd("\")

###SQLServer module to be imported if it exists or continue with SQLPS module
$IsSQLServerModulePresent = Get-Module sqlserver -ListAvailable
if ($IsSQLServerModulePresent) {
	$IsSQLPSLoaded = (Get-Module | Where-Object { $_.Name -eq "sqlps" -and $_.Version -ne "0.0" }).Name
	if ($IsSQLPSLoaded) {
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
###
	
$SQLInstallationPathQuery = "
declare @rc int, @dir nvarchar(4000) 

exec @rc = master.dbo.xp_instance_regread
      N'HKEY_LOCAL_MACHINE',
      N'Software\Microsoft\MSSQLServer\Setup',
      N'SQLPath', 
      @dir output, 'no_output'
select @dir AS InstallationDirectory
"
$SQLInstallationPath = (Invoke-SQLCmd -serverinstance $Server -Query $SQLInstallationPathQuery | Select-Object -expandproperty InstallationDirectory | out-string).TrimEnd("")
$Path = split-path -parent $MyInvocation.MyCommand.Definition

if ((Test-Connection $Servername -quiet) -eq $TRUE) {
	$SQLProcess = "test"
	#$SQLProcess = Get-Service | where-object { $_.Name -eq "MSSQLSERVER" -AND $_.Status -eq "Running" }
	if ($SQLProcess) {
		$DataDriveFolder = $DataDrive + ":\SQL_Data"
		if ((Test-Path $DataDriveFolder) -eq $FALSE) {
			mkdir $DataDriveFolder
		}
		$LogDriveFolder = $LogDrive + ":\SQL_Logs"
		if ((Test-Path $LogDriveFolder) -eq $FALSE) {
			mkdir $LogDriveFolder
		}
		$SQL_Trace = Invoke-SQLCmd -serverinstance $server -query "Select name from sys.databases where name = 'SQL_TRACE'" | Select-Object -ExpandProperty name
		if (!$SQL_Trace) {
			$Create_SQL_TRACE_QUERY = "
				CREATE DATABASE [SQL_Trace]
				CONTAINMENT = NONE
				ON  PRIMARY 
				( NAME = N'SQL_Trace', FILENAME = N'$DataDriveFolder\SQL_Trace.mdf' , SIZE = 4096KB , FILEGROWTH = 102400KB )
				LOG ON 
				( NAME = N'SQL_Trace_log', FILENAME = N'$LogDriveFolder\SQL_Trace_log.ldf' , SIZE = 1024KB , FILEGROWTH = 204800KB)
				GO
				ALTER DATABASE [SQL_Trace] SET RECOVERY SIMPLE 
				GO
				"
			if (!$WhatIf) {
				Write-Host "WARNING: SQL_Trace database does not exist! Creating SQL_Trace Database on default SQL server drives. Please move once setup completes if necessary." -foreground yellow
				Invoke-SQLCmd -serverinstance $server -query $Create_SQL_TRACE_QUERY
			}
			else {
				Write-Host "Invoke-SQLCmd -serverinstance $server -query $Create_SQL_TRACE_QUERY"
			}
		}
		Write-Host "Beginning setup for $server........"
		$MaxDOP_SQL_Query = "SELECT COUNT(DISTINCT memory_node_id) AS NUMA_Nodes FROM sys.dm_os_memory_clerks WHERE memory_node_id!=64"
		$MaxDOP_SQL = Invoke-SQLCmd -ServerInstance $Server -query $MaxDOP_SQL_Query | Select-Object -expandproperty NUMA_Nodes
		$MaxDOP_Powershell = Invoke-Command -ComputerName $Servername -ScriptBlock { Get-WmiObject -namespace "root\CIMV2" -class Win32_Processor -Property NumberOfCores | Select-Object NumberOfCores } | Select-Object -expandproperty NumberOfCores
		$MaxDOP_Powershell = $MaxDOP_Powershell | Measure-Object -maximum | Select-Object -ExpandProperty maximum
		$MaxDOP = $MaxDOP_Powershell / $MaxDOP_SQL
		$RAM = [Math]::Round((Get-WmiObject -Class win32_computersystem -ComputerName $Servername).TotalPhysicalMemory / 1Gb)
		if (!$MinMemory) {
			$MinMemory = $RAM * 0.2
			$MinMemory = [Math]::Ceiling($MinMemory / 10) * 10;
			$MinMemory = [int]$MinMemory * 1000
		}
		if (!$MaxMemory) {
			$MaxMemory = $RAM * 0.8
			$MaxMemory = [Math]::Ceiling($MaxMemory / 10) * 10;
			$MaxMemory = [int]$MaxMemory * 1000
		}
			
		$DataDrive = $DataDrive.TrimEnd("\")
		$LogDrive = $LogDrive.TrimEnd("\")
		$BackupDrive = $BackupDrive.TrimEnd("\")
		$DataDrive = $DataDrive.TrimEnd(":")
		$LogDrive = $LogDrive.TrimEnd(":")
		$BackupDrive = $BackupDrive.TrimEnd(":")
		$SQLJobs = $sqlinfoJson.datacenters.aws.$Environment.Jobs.psobject.properties.name  | sort-object
		$smtp = $sqlinfoJson.datacenters.aws.$Environment.smtp
		$TaskAdminUser = $sqlinfoJson.datacenters.aws.$Environment.TaskAdmin
		$Email_Address = "$Server@Desire2Learn.com"
		Set-Location $path\AWS\
		$TestPath = Test-Path .\Temp
		if ($TestPath -eq $false) {
			New-Item -type Directory temp
		}
		else {
			Remove-Item $Path\AWS\Temp -recurse -force
			New-Item -type Directory temp			
		}
					
		Set-Location $path\Jobs\	
		$TestPath = Test-Path .\Temp
		if ($TestPath -eq $true) {
			Remove-Item $Path\Jobs\Temp -recurse -force
		}
		$Jobs = Get-ChildItem | Select-Object -expandproperty BaseName | sort-object
		New-Item -type Directory temp
			
		if (Compare-Object $SQLJobs $Jobs) {
			Write-Host "Jobs in repo and jobs in directory do not match. Exiting setup with no action." -foreground red
		}
				
		Set-Location $path\AWS\
		$Requires_Edits = Get-ChildItem | where-object name -ne "temp" | Select-Object -expandproperty Name
		foreach ($Requires_Edit_Script in $Requires_Edits) {
			$Script = Get-Content "$Path\AWS\$Requires_Edit_Script"
			$Script = $Script -replace "<MaxDOP>" , $MAXDop
			$Script = $Script -replace "<MaxMemory>" , $MaxMemory
			$Script = $Script -replace "<MinMemory>" , $MinMemory
			$Script = $Script -replace "<TempDBDirectory>" , $TempDBDirectory
			$Script = $Script -replace "<Email_Address>" , $Email_Address
			$Script = $Script -replace "<environment>" , $Environment
			$Script = $Script -replace "<smtp>" , $smtp
			$Script = $Script -replace "<DataDrive>" , $DataDrive
			$Script = $Script -replace "<LogDrive>" , $LogDrive
			$Script = $Script -replace "<BackupDrive>" , $BackupDrive
			$Script = $Script -replace "<TaskAdminPassword>" , $TaskAdminPassword
			$Script = $Script -replace "<TaskAdminUser>" , $TaskAdminUser
			$Script = $Script -replace "<SQLInstallationPath>" , $SQLInstallationPath
			$Script | Set-Content .\Temp\$Requires_Edit_Script
			if (!$WhatIf) {
				Write-Host "Executing $Requires_Edit_Script"
				Invoke-SQLCmd -ServerInstance $Server -inputfile "$Path\AWS\Temp\$Requires_Edit_Script" -QueryTimeout 0
				Write-Host "Complete"
			}
			else {
				Write-Host "Invoke-SQLCmd -ServerInstance $Server -inputfile '$Path\AWS\Temp\$Requires_Edit_Script'"
			}
		}
				
		if (!$WhatIf) {
			Remove-Item $Path\AWS\Temp\* -recurse -force
		}
						
		if (!$WhatIf) {
			Remove-Item $Path\AWS\Temp -recurse -force
		}
		Set-Location $path\Jobs\	
		foreach ($Job in $Jobs) {
			$JobStartTime = $sqlinfoJson.datacenters.aws.$environment.jobs.$Job.StartTimeUTC
			$JobStopTime = $sqlinfoJson.datacenters.aws.$environment.jobs.$Job.StopTimeUTC
			$JobEnabled = $sqlinfoJson.datacenters.aws.$environment.jobs.$Job.Enabled
			$JobEnabled = [System.Convert]::ToBoolean($JobEnabled)
			$JobEnabled = [int]$JobEnabled				
			$Script = Get-Content "$Path\Jobs\$Job.sql"
			$Script = $Script -replace "<environment>" , $Environment
			$Script = $Script -replace "<starttime>", $JobStartTime
			$Script = $Script -replace "<stoptime>", $JobStopTime
			$Script = $Script -replace "<JobEnabled>", $JobEnabled
			$Script | Set-Content .\Temp\$Job.sql
			if (!$WhatIf) {
				Write-Host "Executing $Job.sql"
				Invoke-SQLCmd -ServerInstance $Server -inputfile "$Path\Jobs\Temp\$Job.sql" -QueryTimeout 0 -DisableVariables
				Write-Host "Complete"
			}
			else {
				Write-Host "Invoke-SQLCmd -ServerInstance $Servername -inputfile '$Path\Jobs\Temp\$Job.sql' -DisableVariables"
			}
		}
		if (!$WhatIf) {
			Remove-Item $Path\Jobs\Temp\* -recurse -force
		}
						
		if (!$WhatIf) {
			Remove-Item $Path\Jobs\Temp -recurse -force
		}
	
		if (!$WhatIf) {
			C:\DBA_Scripts\Setup_Scripts\SQLConfigurationManagerSetup_Jenkins_fci.ps1 -Servername $Servername -SqlInstanceName $SqlInstanceName
		}
		else {
			Write-Host "SQLConfigurationManagerSetup_Jenkins.ps1 -Servers $server"
		}

		if (!$WhatIf) {
			Write-Host "Disabling NETBIOS for NIC"
			$adaptername = Get-NetIPConfiguration | Select-Object -ExpandProperty InterfaceDescription
			$adapter = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object Description -eq $adaptername
			$adapter.SetTcpIPNetbios(2) | Select-Object ReturnValue
		}
	}
	else {
		Write-Host "SQL Service is not running" -foreground red
		exit
	}
}
else {
	Write-Host "$Server not found" -foreground red
	exit
}