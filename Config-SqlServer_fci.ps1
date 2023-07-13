<#
    	.Synopsis
		Runs Sql Scripts required to complete setup. Should be run right after Sql Install has been completed.
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
	[parameter(Mandatory = $false)][switch]$whatif
)

if ((Test-Path C:\Modules\Sql_Admin.psm1) -eq $false) {
	Write-Host "Sql_Admin.psm1 not found."
	exit
}

Import-Module C:\Modules\Sql_Admin.psm1 -force
$SqlInfoJson = Get-SqlInfo
$Environment = Get-Environment
$Server = "$ServerName\$SqlInstanceName"
$TempDBDirectory = $TempDBDirectory.TrimEnd("\")

###SQLServer module to be imported if it exists or continue with SqlPS module
$IsSqlServerModulePresent = Get-Module SqlServer -ListAvailable
if ($IsSQLServerModulePresent) {
	$IsSqlPSLoaded = (Get-Module | Where-Object { $_.Name -eq "SqlPS" -and $_.Version -ne "0.0" }).Name
	if ($IsSqlPSLoaded) {
		Remove-Module SqlPS
	}
	$CurrentPath = Get-Location
	Import-Module SqlServer -force
	Set-Location $CurrentPath
}
else {
	$CurrentPath = Get-Location
	Import-Module SqlPS -ErrorAction SilentlyContinue
	Set-Location $CurrentPath
}
	
$SqlInstallationPathQuery = "
declare @rc int, @dir nvarchar(4000) 

Exec @rc = master.dbo.xp_instance_regread
      N'HKEY_LOCAL_MACHINE',
      N'Software\Microsoft\MSSQLServer\Setup',
      N'SQLPath', 
      @dir output, 'no_output'
Select @dir AS InstallationDirectory
"
$SqlInstallationPath = (Invoke-SqlCmd -ServerInstance $Server -Query $SqlInstallationPathQuery | Select-Object -ExpandProperty InstallationDirectory | Out-String).TrimEnd("")
$Path = Split-Path -Parent $MyInvocation.MyCommand.Definition

if ((Test-Connection $ServerName -quiet) -eq $true) {
	$SqlProcess = "test"
	#$SqlProcess = Get-Service | where-object { $_.Name -eq "MSSQLSERVER" -AND $_.Status -eq "Running" }
	if ($SqlProcess) {
		$DataDriveFolder = $DataDrive + ":\Sql_Data"
		if ((Test-Path $DataDriveFolder) -eq $false) {
			mkdir $DataDriveFolder
		}
		$LogDriveFolder = $LogDrive + ":\Sql_Logs"
		if ((Test-Path $LogDriveFolder) -eq $false) {
			mkdir $LogDriveFolder
		}
		$Sql_Trace = Invoke-SqlCmd -ServerInstance $Server -Query "Select name from sys.databases where name = 'SQL_Trace'" | Select-Object -ExpandProperty name
		if (!$Sql_Trace) {
			$Create_SQL_Trace_Query = "
				CREATE DATABASE [SQL_Trace]
				CONTAINMENT = NONE
				ON  PRIMARY 
				( NAME = N'Sql_Trace', FILENAME = N'$DataDriveFolder\Sql_Trace.mdf' , SIZE = 4096KB , FILEGROWTH = 102400KB )
				LOG ON 
				( NAME = N'Sql_Trace_log', FILENAME = N'$LogDriveFolder\Sql_Trace_log.ldf' , SIZE = 1024KB , FILEGROWTH = 204800KB)
				GO
				ALTER DATABASE [Sql_Trace] SET RECOVERY SIMPLE 
				GO
				"
			if (!$whatif) {
				Write-Host "WARNING: Sql_Trace database does not exist! Creating Sql_Trace Database on default Sql server drives. Please move once setup completes if necessary." -foreground yellow
				Invoke-SqlCmd -ServerInstance $Server -Query $Create_Sql_Trace_Query
			}
			else {
				Write-Host "Invoke-SqlCmd -ServerInstance $Server -Query $Create_SQL_Trace_Query"
			}
		}
		Write-Host "Beginning setup for $Server........"
		$MaxDop_Sql_Query = "SELECT COUNT(DISTINCT memory_node_id) AS NUMA_Nodes FROM sys.dm_os_memory_clerks WHERE memory_node_id!=64"
		$MaxDop_Sql = Invoke-SqlCmd -ServerInstance $Server -Query $MaxDop_Sql_Query | Select-Object -ExpandProperty NUMA_Nodes
		$MaxDop_PowerShell = Invoke-Command -ComputerName $ServerName -ScriptBlock { Get-WmiObject -NameSpace "root\CIMV2" -class Win32_Processor -Property NumberOfCores | Select-Object NumberOfCores } | Select-Object -ExpandProperty NumberOfCores
		$MaxDop_PowerShell = $MaxDop_PowerShell | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
		$MaxDop = $MaxDop_PowerShell / $MaxDop_Sql
		$Ram = [Math]::Round((Get-WmiObject -Class win32_computersystem -ComputerName $ServerName).TotalPhysicalMemory / 1Gb)
		if (!$MinMemory) {
			$MinMemory = $Ram * 0.2
			$MinMemory = [Math]::Ceiling($MinMemory / 10) * 10;
			$MinMemory = [int]$MinMemory * 1000
		}
		if (!$MaxMemory) {
			$MaxMemory = $Ram * 0.8
			$MaxMemory = [Math]::Ceiling($MaxMemory / 10) * 10;
			$MaxMemory = [int]$MaxMemory * 1000
		}
			
		$DataDrive = $DataDrive.TrimEnd("\")
		$LogDrive = $LogDrive.TrimEnd("\")
		$BackupDrive = $BackupDrive.TrimEnd("\")
		$DataDrive = $DataDrive.TrimEnd(":")
		$LogDrive = $LogDrive.TrimEnd(":")
		$BackupDrive = $BackupDrive.TrimEnd(":")
		$SqlJobs = $SqlInfoJson.DataCenters.Aws.$Environment.Jobs.PSObject.Properties.Name  | Sort-Object
		$Smtp = $SqlInfoJson.DataCenters.Aws.$Environment.Smtp
		$TaskAdminUser = $SqlInfoJson.DataCenters.Aws.$Environment.TaskAdmin
		$Email_Address = "$Server@Desire2Learn.com"
		Set-Location $Path\Aws\
		$TestPath = Test-Path .\Temp
		if ($TestPath -eq $false) {
			New-Item -Type Directory Temp
		}
		else {
			Remove-Item $Path\Aws\Temp -recurse -force
			New-Item -Type Directory Temp			
		}
					
		Set-Location $Path\Jobs\	
		$TestPath = Test-Path .\Temp
		if ($TestPath -eq $true) {
			Remove-Item $Path\Jobs\Temp -recurse -force
		}
		$Jobs = Get-ChildItem | Select-Object -ExpandProperty BaseName | Sort-Object
		New-Item -Type Directory Temp
			
		if (Compare-Object $SqlJobs $Jobs) {
			Write-Host "Jobs in repo and jobs in directory do not match. Exiting setup with no action."
		}
				
		Set-Location $Path\Aws\
		$Requires_Edits = Get-ChildItem | Where-Object Name -ne "Temp" | Select-Object -ExpandProperty Name
		foreach ($Requires_Edit_Script in $Requires_Edits) {
			$Script = Get-Content "$Path\Aws\$Requires_Edit_Script"
			$Script = $Script -replace "<MaxDop>" , $MaxDop
			$Script = $Script -replace "<MaxMemory>" , $MaxMemory
			$Script = $Script -replace "<MinMemory>" , $MinMemory
			$Script = $Script -replace "<TempDBDirectory>" , $TempDBDirectory
			$Script = $Script -replace "<Email_Address>" , $Email_Address
			$Script = $Script -replace "<Environment>" , $Environment
			$Script = $Script -replace "<Smtp>" , $Smtp
			$Script = $Script -replace "<DataDrive>" , $DataDrive
			$Script = $Script -replace "<LogDrive>" , $LogDrive
			$Script = $Script -replace "<BackupDrive>" , $BackupDrive
			$Script = $Script -replace "<TaskAdminPassword>" , $TaskAdminPassword
			$Script = $Script -replace "<TaskAdminUser>" , $TaskAdminUser
			$Script = $Script -replace "<SqlInstallationPath>" , $SqlInstallationPath
			$Script | Set-Content .\Temp\$Requires_Edit_Script
			if (!$whatif) {
				Write-Host "Executing $Requires_Edit_Script"
				Invoke-SqlCmd -ServerInstance $Server -Inputfile "$Path\Aws\Temp\$Requires_Edit_Script" -QueryTimeout 0
				Write-Host "Complete"
			}
			else {
				Write-Host "Invoke-SqlCmd -ServerInstance $Server -inputfile '$Path\Aws\Temp\$Requires_Edit_Script'"
			}
		}
				
		if (!$whatif) {
			Remove-Item $Path\Aws\Temp\* -recurse -force
		}
						
		if (!$whatif) {
			Remove-Item $Path\Aws\Temp -recurse -force
		}
		Set-Location $Path\Jobs\	
		foreach ($Job in $Jobs) {
			$JobStartTime = $SqlInfoJson.DataCenters.Aws.$Environment.jobs.$Job.StartTimeUTC
			$JobStopTime = $SqlInfoJson.DataCenters.Aws.$Environment.jobs.$Job.StopTimeUTC
			$JobEnabled = $SqlInfoJson.DataCenters.Aws.$Environment.jobs.$Job.Enabled
			$JobEnabled = [System.Convert]::ToBoolean($JobEnabled)
			$JobEnabled = [int]$JobEnabled				
			$Script = Get-Content "$Path\Jobs\$Job.Sql"
			$Script = $Script -replace "<Environment>" , $Environment
			$Script = $Script -replace "<StartTime>", $JobStartTime
			$Script = $Script -replace "<StopTime>", $JobStopTime
			$Script = $Script -replace "<JobEnabled>", $JobEnabled
			$Script | Set-Content .\Temp\$Job.Sql
			if (!$whatif) {
				Write-Host "Executing $Job.Sql"
				Invoke-SqlCmd -ServerInstance $Server -Inputfile "$Path\Jobs\Temp\$Job.Sql" -QueryTimeout 0 -DisableVariables
				Write-Host "Complete"
			}
			else {
				Write-Host "Invoke-SqlCmd -ServerInstance $ServerName -inputfile '$Path\Jobs\Temp\$Job.Sql' -DisableVariables"
			}
		}
		if (!$whatif) {
			Remove-Item $Path\Jobs\Temp\* -recurse -force
		}
						
		if (!$whatif) {
			Remove-Item $Path\Jobs\Temp -recurse -force
		}
	
		if (!$whatif) {
			C:\DBA_Scripts\Setup_Scripts\SqlConfigurationManagerSetup_Jenkins_Fci.ps1 -ServerName $ServerName -SqlInstanceName $SqlInstanceName
		}
		else {
			Write-Host "SqlConfigurationManagerSetup_Jenkins_Fci.ps1 -ServerName $ServerName -SqlInstanceName $SqlInstanceName"
		}

		if (!$whatif) {
			Write-Host "Disabling NetBios for NIC"
			$AdapterName = Get-NetIpConfiguration | Select-Object -ExpandProperty InterfaceDescription
			$Adapter = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object Description -eq $AdapterName
			$Adapter.SetTcpIpNetBios(2) | Select-Object ReturnValue
		}
	}
	else {
		Write-Host "SQL Service is not running"
		exit
	}
}
else {
	Write-Host "$Server not found"
	exit
}