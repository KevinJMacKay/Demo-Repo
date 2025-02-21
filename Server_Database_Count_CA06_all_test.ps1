param (    
    [parameter(Mandatory = $false)][array]$SQLServers,
	[parameter(Mandatory = $false)][switch]$ReportingServersOnly,
	[parameter(Mandatory = $false)][switch]$TestServersOnly,
	[parameter(Mandatory = $false)][switch]$CorpProdServersOnly,
	[parameter(Mandatory = $false)][switch]$AcadProdServersOnly,	
    [Parameter(Mandatory = $false)][ValidateSet('US04', 'CA05', 'EU01', 'AP02', 'AP01')][array]$environments
)

if (!$environments -AND !$SQLServers) {
    $Environments = @("US04", "EU01", "CA05", "AP01", "AP02")  
}

$awsenvironments = @("US04", "EU01", "CA05", "AP01", "AP02")
	
if (!$SQLServers) {
    if ((Test-Path C:\Modules\SQL_Admin_Universal.psm1) -eq $FALSE) {
        Write-Host "SQL_Admin_Universal.psm1 not found."
        Exit
    }
    Import-Module C:\Modules\SQL_Admin_Universal.psm1 -Force
    Import-Module sqlps -Force
    Set-Location c:
	
    $dbinfoJson = Get-dbinfo
    
    foreach ($environment in $environments) {
		if ($awsenvironments -contains $environment){
			$listeners = $dbinfoJson.datacenters.$environment.listeners.psobject.properties.name
			foreach ( $listener in $listeners ) {
				$listenerobject = $dbinfoJson.datacenters.$environment.listeners.$listener
				$Servers = $listenerobject.servers
				$SQLServers = $SQLServers + $Servers
				$SQLServers = $SQLServers | select-object -unique | sort-object
				if($ReportingServersOnly){
				$SQLServers = $SQLServers | Where-Object {$_ -like "*RSQL*"}
				}
				if($TestServersOnly){
				$SQLServers = $SQLServers | Where-Object {$_ -like "*TSQL*"}
				}
				if($CorpProdServersOnly){
				$SQLServers = $SQLServers | Where-Object {$_ -like "*CPSQL*"}
				}
				if($AcadProdServersOnly){
				$SQLServers = $SQLServers | Where-Object {$_ -like "*APSQL*"}
				}
			}
		} 
	}
}

foreach ($SQLServer in $SQLServers) {
	$DBCount = $NULL
    $Region = $SQLServer.Substring(0, 4)
    if ($Region -eq "US04") {
        $Domain = ".aue1.int.d2l"
    }
    ELSEIF ($Region -eq "CA05") {
        $Domain = ".acc1.int.d2l"
    }
    ELSEIF ($Region -eq "AP02") {
        $Domain = ".aas2.int.d2l"
    }
    ELSEIF ($Region -eq "AP01") {
        $Domain = ".aas1.int.d2l"
    }
    ELSEIF ($Region -eq "AAS1") {
        $Domain = ".aas1.int.d2l"
    }
    ELSEIF ($Region -eq "EU01") {
        $Domain = ".aew1.int.d2l"
    }
	ELSE {
		Write-Host "Domain not found" -foreground red
		continue
	}
	if ($SQLServer -like "*,*"){
		$SQLServer = $SQLServer -replace ",",$domain
	}
	else {
		$SQLServer = $($SQLServer) + $($Domain)
		}
	
	$query = "Select Count(*) AS DBCount from sys.databases Where database_ID > 4"
	Write-Host $SQLServer
	$DBCount = Invoke-SQLcmd -ServerInstance $SQLServer -Query $Query -QueryTimeout 0 | Select -expandProperty dbCount
	
    if ($Region -eq "US04") {
	$US04DBCount = $US04DBCount + $DBCount
	$US04val++	
	}	
	if ($Region -eq "CA05") {
	$CA05DBCount = $CA05DBCount + $DBCount 
	$CA05val++
	}
	if ($Region -eq "EU01") {
	$EU01DBCount = $EU01DBCount + $DBCount 
	$EU01val++
	}
	if ($Region -eq "AP02") {
	$AP02DBCount = $AP02DBCount + $DBCount 
	$AP02val++
	}
	if ($Region -eq "AP01") {
	$AP01DBCount = $AP01DBCount + $DBCount 
	$AP01val++
	}

	$AllDBCount = $AllDBCount + $DBCount 
}
$date = date
Write-Host "`nRun Date: $date" 
Write-Host "`nUS04 Server count: "$US04val	
Write-Host "US04 Database Count: $US04DBCount"
Write-Host "`nCA05 Server count: "$CA05val	
Write-Host "CA05 Database Count: $CA05DBCount"
Write-Host "`nEU01 Server count: "$EU01val	
Write-Host "EU01 Database Count: $EU01DBCount"
Write-Host "`nAP02 Server count: "$AP02val	
Write-Host "AP02 Database Count: $AP02DBCount"
Write-Host "`nAP01 Server count: "$AP01val	
Write-Host "AP01 Database Count: $AP01DBCount"

Write-Host "`nTotal Server count: "$SQLServers.count
Write-Host "Total Database Count: $AllDBCount"
