param (   
	[parameter(Mandatory = $true)][string]$ServerName,
	[parameter(Mandatory = $true)][string]$SqlInstanceName
)

if ((Test-Path C:\Modules\Sql_Admin.psm1) -eq $false) {
	Write-Host "Sql_Admin.psm1 not found."
	Exit
}

$Server = "$ServerName\$SqlInstanceName"

Import-Module C:\Modules\Sql_Admin.psm1

#SqlServer module to be imported if it exists or continue with SqlPS module
$IsSqlServerModulePresent = Get-Module SqlServer -ListAvailable
if ($IsSqlServerModulePresent) {
	$IsSqlPSLoaded = (Get-Module | Where-Object { $_.Name -eq "SqlPS" -and $_.Version -ne "0.0" }).Name
	if ($IsSqlPSLoaded) {
		Remove-Module SqlPS
	}

	$CurrentPath = Get-Location
	Import-Module SqlServer -Force
	Set-Location $CurrentPath
}
else {
	$CurrentPath = Get-Location
	Import-Module SqlPS -ErrorAction SilentlyContinue
	Set-Location $CurrentPath
}

$SqlInfoJson = Get-SqlInfo
$Parameters = $SqlInfoJson.DataCenters.Aws.StartupParameters

$SqlVersion = Invoke-SqlCmd -ServerInstance $Server -Query "Select SERVERPROPERTY('ProductMajorVersion')" | Select-Object -ExpandProperty column1
$RegKey = $NULL
if ($SqlVersion -eq 15) {
	$RegKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.$SqlInstanceName\MSSQLServer\Parameters"
}
else {
	Write-Host "Unknown SQL version detected. Exiting StartupParameter setup....."
	Break
}
	
if ($NULL -eq $RegKey) {
	Write-Host "Unable to find registry entry for $SqlVersion. Exiting StartupParameter setup....."
	Break
}
		
Write-Host "`nAdding Startup Parameters on $Server" 
$Property = Get-ItemProperty $RegKey
$ParamObjects = $Property.PSObject.Properties | Where-Object { $_.Name -like 'SqlArg*' }
$Count = $ParamObjects.count
	
foreach ($Parameter in $Parameters) {
	if ($Parameter -notin $ParamObjects.value) {           
		Write-Host "Adding startup Parameter:SqlArg$count for $Parameter"
		$NewRegProp = "SqlArg" + $count
		Set-ItemProperty -Path $RegKey -Name $NewRegProp -Value $Parameter
		Write-Host "Added Startup Parameter $NewRegProp : $Parameter"
		$Count ++
	}
}

Write-Host "Attempting to enable AlwaysOn on $Server"
Write-Host "Enable-SqlAlwaysOn -Path SQLSERVER:\SQL\$Server -NoServiceRestart"
Enable-SqlAlwaysOn -Path SQLSERVER:\SQL\$Server -NoServiceRestart

Write-Host "`nAttempting to restart SQL..."
Restart-Service -Force "MSSQL`$$SqlInstanceName"
Start-Sleep 5
$ServiceStatus = (Get-Service "MSSQL`$$SqlInstanceName").status
if ($ServiceStatus -ne "Running") {
	Write-Host "SQL failed to restart"
}
else {
	Write-Host "SQL Successfully restarted"
}

$Count2 = 0
$AgentServiceStatus = (Get-Service "SQLAgent`$$SqlInstanceName").status
Write-Host "SQLAgent Service status:"$ServiceStatus
while ($Count2 -le 5 -and $AgentServiceStatus -ne "Running") {
	Write-Host "SQLAgent is NOT running but $AgentServiceStatus. Attempting to restart..."
	Start-Service "SQLAgent`$$SqlInstanceName"
	Start-Sleep 5
	$AgentServiceStatus = (Get-Service "SQLAgent`$$SqlInstanceName").status
	$Count2 ++
}

$ClusAgentStatus = (Get-ClusterResource | Where-Object { $_.ResourceType -eq "SQL Server Agent" }).state
Write-Host "Cluster SQL Agent Service status: "$ClusAgentStatus
if ($ClusAgentStatus -ne "Online") {
	Write-Host "Starting Cluster SQL Agent Service"
	Get-ClusterResource | Where-Object { $_.ResourceType -eq "SQL Server Agent" } | Start-ClusterResource | Out-Null
	$ClusAgentStatus = (Get-ClusterResource | Where-Object { $_.ResourceType -eq "SQL Server Agent" }).state
	Write-Host "Cluster SQL Agent Service status: "$ClusAgentStatus
}

$AlwaysOnEnabled = Invoke-SqlCmd -ServerInstance $Server -query "SELECT SERVERPROPERTY ('IsHadrEnabled') AS 'IsHadrEnabled';" | Select-Object -ExpandProperty IsHadrEnabled
if ($AlwaysOnEnabled -eq 1) {
	Write-Host "`nAlwaysOn is Enabled"
}
else {
	Write-Host "`nAlwaysOn failed to enable. Attempting to temporarily increase WMI HandlesPerHost threshold from 4096 to 128000 and retry..."
	Invoke-Command -ComputerName $ServerName -AsJob -JobName "Wmi_Monitor" -ScriptBlock {
		while ($Counter -lt 1000) {
			Get-Process | Where-Object { $_.ProcessName -like "*WMI*" } | Sort-Object { $_.Handles } -Descending | Select-Object -First 1
			Start-Sleep 1
			$Counter ++
		}
	}
		
	$WmiHt = @{           
		NameSpace = 'root'           
		Class     = '__ProviderHostQuotaConfiguration'           
	}           
		 
	$WmiProviderConfig = Get-WmiObject @WmiHt       
	$WmiProviderConfig.HandlesPerHost = 128000
		
	try {
			
		$WmiProviderConfig.Put() | Out-Null           
		Write-Host "Successfully changed the WMI provider settings" -Verbose    

		Write-Host "Re-Attempting to enable AlwaysOn"
		Enable-SqlAlwaysOn -Path SQLSERVER:\SQL\$Server -NoServiceRestart
		Restart-Service -force "MSSQL`$$SqlInstanceName"
			
		Write-Host "Setting WMI HandlesPerHost threshold back to 4096..."
		$WmiProviderConfig.HandlesPerHost = 4096
		$WmiProviderConfig.Put() | Out-Null
	} 
	catch { 
		Write-Warning "Failed to modify the WMI provider because $($_.Exception.Message)"
	}
		
	$AlwaysOnEnabled = Invoke-SqlCmd -ServerInstance $Server -query "SELECT SERVERPROPERTY ('IsHadrEnabled') AS 'IsHadrEnabled';" | Select-Object -ExpandProperty IsHadrEnabled
		
	if ($AlwaysOnEnabled -eq 1) {
		Write-Host "`nSecond attempt to enable AlwaysOn was successful after WMI HandlesPerHost threshold settings change."
	}
	else {
		Write-Host "`nSecond attempt to enable AlwaysOn wasn't successful after WMI HandlesPerHost threshold settings change."
	}
	$Results = Receive-Job -Name "Wmi_Monitor" | Select-Object -last 1
	Stop-Job -Name "Wmi_Monitor"
	$Handles = $Results.Handles
	Write-Host "Handles used $Handles"

	$count3 = 0
	$AgentServiceStatus = (Get-Service "SQLAgent`$$SqlInstanceName").status
	Write-Host "SQLAgent Service status:"$ServiceStatus
	while ($count3 -le 5 -and $AgentServiceStatus -ne "Running") {
		Write-Host "SQLAgent is NOT running. Attempting to restart..."
		Start-Service "SQLAgent`$$SqlInstanceName"
		Start-Sleep 5
		$ServiceStatus = (Get-Service "SQLAgent`$$SqlInstanceName").status
		$count3 ++
	}

	$ClusAgentStatus = (Get-ClusterResource | Where-Object { $_.ResourceType -eq "SQL Server Agent" }).State
	Write-Host "Cluster SQL Agent Service status: "$ClusAgentStatus
	if ($ClusAgentStatus -ne "Online") {
		Get-ClusterResource | Where-Object { $_.ResourceType -eq "SQL Server Agent" } | Start-ClusterResource
		$ClusAgentStatus = (Get-ClusterResource | Where-Object { $_.ResourceType -eq "SQL Server Agent" }).State
		Write-Host "Cluster SQL Agent Service status: "$ClusAgentStatus
	}
}	
