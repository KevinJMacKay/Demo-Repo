param (   
	[parameter(Mandatory = $true)][string]$ServerName,
	[parameter(Mandatory = $true)][string]$SqlInstanceName
)

if ((Test-Path C:\Modules\SQL_Admin.psm1) -eq $false) {
	Write-Host "SQL_Admin.psm1 not found."
	Exit
}

$Server = "$ServerName\$SqlInstanceName"

Import-Module C:\Modules\SQL_Admin.psm1

#SQLServer module to be imported if it exists or continue with SQLPS module
$IsSQLServerModulePresent = Get-Module sqlserver -ListAvailable
if($IsSQLServerModulePresent) {
	$IsSQLPSLoaded = (Get-Module | Where {$_.Name -eq "sqlps" -and $_.Version -ne "0.0"}).Name
	if($IsSQLPSLoaded) {
		Remove-Module sqlps
	}

	$CurrentPath = Get-Location
	Import-Module sqlserver -Force
	Set-Location $CurrentPath
}
else {
	$CurrentPath = Get-Location
	Import-Module sqlps -EA silentlyContinue
	Set-Location $CurrentPath
}

$sqlinfoJson = Get-sqlinfo
$parameters = $sqlinfoJson.datacenters.aws.startupparameters

$SQLVersion = Invoke-SQLCmd -ServerInstance $Server -Query "select SERVERPROPERTY('ProductMajorVersion')" | Select-Object -expandproperty column1
$RegKey = $NULL
if ($SQLVersion -eq 12) {
	$regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer\Parameters" 
}
elseif ($SQLVersion -eq 13) {
	$regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQLServer\Parameters"
}
elseif ($SQLVersion -eq 15) {
	$regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQLServer\Parameters"
}
else {
	Write-Host "Unknown SQLVersion detected. Exiting StartupParameter setup....."
	Break
}
	
if ($regKey -eq $NULL) {
	Write-Host "Unable to find registry entry for $SQLVersion. Exiting StartupParameter setup....."
	Break
}
		
Write-Host "`nAdding startupparameters on $Server" 
		
Invoke-Command -ComputerName $servername -ScriptBlock { param ($parameters, $regKey, $Server)
	$property = Get-ItemProperty $regKey
	$paramObjects = $property.psobject.properties | ? { $_.Name -like 'SQLArg*' }
	$count = $paramObjects.count
		
	foreach ($parameter in $parameters) {
		if ($parameter -notin $paramObjects.value) {           
			Write-Host "Adding startup parameter:SQLArg$count for $parameter"
			$newRegProp = "SQLArg" + $count
			Set-ItemProperty -Path $regKey -Name $newRegProp -Value $parameter
			Write-Host "Added Startup Parameter $newRegProp : $parameter"
			$count = $count + 1
		}
	}
		
	#Import-Module sqlps
	#SQLServer module to be imported if it exists or continue with SQLPS module
	$IsSQLServerModulePresent = Get-Module sqlserver -ListAvailable
	if($IsSQLServerModulePresent) {
		$IsSQLPSLoaded = (Get-Module | Where {$_.Name -eq "sqlps" -and $_.Version -ne "0.0"}).Name
		if($IsSQLPSLoaded) {
			Remove-Module sqlps
		}

		$CurrentPath = Get-Location
		Import-Module sqlserver -Force
		Set-Location $CurrentPath
	}
	else {
		$CurrentPath = Get-Location
		Import-Module sqlps -EA silentlyContinue
		Set-Location $CurrentPath
	}
		
	Write-Host "Attempting to enable always on on $server"
	Write-Host "Enable-SqlAlwaysOn -Path SQLSERVER:\SQL\$Server -NoServiceRestart"
	Enable-SqlAlwaysOn -Path SQLSERVER:\SQL\$Server -NoServiceRestart
	Write-Host "`nAttempting to restart SQL..."
	Restart-Service -Force 'SQLAgent$INSTA'
	Restart-Service -Force 'MSSQL$INSTA'
    Start-Sleep 15
	$ServiceStatus = (Get-Service MSSQLSERVER).status
	if ($ServiceStatus -ne "Running") {
		Write-Host "SQL failed to restart"
	}
	else {
		Write-Host "SQL Successfully restarted"
	}
		
} -ArgumentList $parameters, $regKey, $server

$AlwaysOnEnabled = Invoke-SQLCmd -serverinstance $server -query "SELECT SERVERPROPERTY ('IsHadrEnabled');" | select -expandproperty column1

if ($AlwaysOnEnabled -eq 1) {
		
	Write-Host "`nAlwaysOn is Enabled"
		
}
else {
	
	#Write-Host "`nAlwaysOn is Disabled"
	Write-Host "`nAlwaysOn failed to enable so attempting to temporarily increase WMI HandlesPerHost threshold from 4096 to 128000 and retry..."
	Invoke-Command -ComputerName $servername -AsJob -JobName "WMI_Monitor" -ScriptBlock {
		while ($counter -lt 1000) {
			Get-Process | Where-Object {$_.ProcessName -like "*WMI*"} | Sort-Object {$_.Handles} -Descending | Select-Object -First 1
			start-sleep 1
			$counter ++
		}
	}
		
	$WMIHT = @{           
		NameSpace=  'root'           
		Class = '__ProviderHostQuotaConfiguration'           
	}           
		 
	$WMIProviderConfig = Get-WmiObject @WMIHT       
	$WMIProviderConfig.HandlesPerHost = 128000
		
	try {
			
		$WMIProviderConfig.Put() | Out-Null           
		Write-Host "Successfully changed the WMI provider settings" -Verbose    

		Write-Host "Re-Attempting to enable AlwaysOn"
		Enable-SqlAlwaysOn -Path SQLSERVER:\SQL\$Server -NoServiceRestart
		Restart-Service -Force MSSQL$INSTA
			
		Write-Host "Setting WMI HandlesPerHost threshold back to 4096..."
		$WMIProviderConfig.HandlesPerHost = 4096
		$WMIProviderConfig.Put() | Out-Null
			
	} 
	catch { 
		
		Write-Warning "Failed to modify the WMI provider because $($_.Exception.Message)"
			
	}
		
	$AlwaysOnEnabled = Invoke-SQLCmd -serverinstance $server -query "SELECT SERVERPROPERTY ('IsHadrEnabled');" | select -expandproperty column1
		
	if ($AlwaysOnEnabled -eq 1) {
		
		Write-Host "`nSecond attempt to enable AlwaysOn was successful after WMI HandlesPerHost threshold settings change."
		
	}
	else {
			
		Write-Host "`nSecond attempt to enable AlwaysOn wasn't successful after WMI HandlesPerHost threshold settings change."
			
	}
	$Results = Receive-Job -Name "WMI_Monitor" | Select-Object -last 1
	Stop-Job -Name "WMI_Monitor"
	$Handles = $Results.Handles
	Write-Host "Handles used $Handles"
}	

