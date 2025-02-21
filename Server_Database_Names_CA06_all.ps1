param (    
    [parameter(Mandatory = $false)][array]$SQLServers,
    [Parameter(Mandatory = $false)][ValidateSet('US04', 'CA05', 'EU01', 'AP02', 'AP01')][array]$environments
)


	
if (!$environments -AND !$SQLServers) {
    $Environments = @("US04", "EU01", "CA05", "AP01", "AP02")  
}
$coloenvironments = @("CA3P","CA3D","CA1P","CA1D")  
$awsenvironments = @("US04", "EU01", "CA05", "AP01", "AP02")
	
if ($Environments -contains "CA1P" -OR $Environments -contains "CA1D"){
	$password = Read-Host -assecurestring "Please enter SQL password"
	$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
}
	
if (!$SQLServers) {
    if ((Test-Path C:\Modules\SQL_Admin.psm1) -eq $FALSE) {
        Write-Host "SQL_Admin_Universal.psm1 not found."
        Exit
    }
    Import-Module C:\Modules\SQL_Admin.psm1 -Force
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
			}
		} 
		if ($coloenvironments -contains $environment){
			$Servers = $dbinfoJson.datacenters.$Environment.sqlinstances.psobject.properties.name
			$SQLServers = $SQLServers + $Servers
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
	ELSEIF ($Region -eq "CA1S" -OR $Region -eq "T1SQ"){
		$Domain = ".tor01.desire2learn.d2l,"
	}
	ELSEIF ($Region -eq "CA3S" -OR $Region -eq "CA3F"){
		$Domain = ".ca3.int.d2l,"
	}
	ELSEIF ($Region -eq "CA1D"){
		$Domain = ".tor01.desire2learn.d2l,"
	}
	ELSEIF ($Region -eq "CA3D"){
		$Domain = ".ca3.int.d2l,"
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
	
	$query = "Select @@Servername AS DBServer, name AS DBName from sys.databases Where database_ID > 4
	--AND name in (
	--'4CDTest','AOE_Test','AOE_Prod','ASD20Test','coregolf','css','D2LCDTest','EAPDE','EFTDev','highlandcc','HISD','HISDTest','KNAER','LDCSBTest','LDSTest','LDSStage','minnstateqaA','mundoverde','ParklandTest','PearsonQA','pgtest','Product_Development','RCLTest','SouthCarolinaDev','Unigranrio','UnigranrioNead','UnigranrioNeadTeste','uWaterlooTest','VIUCDTest'
	--)
	
	"
	
	if ($Region -like "CA1*" -OR $Region -like "T1*"){ 
		$DBCount = Invoke-SQLcmd -ServerInstance $SQLServer -Query $Query -QueryTimeout 0 -Username DBAExec -password $password | Select -expandProperty dbCount
	}
	else {
		$DBNames = Invoke-SQLcmd -ServerInstance $SQLServer -Query $Query -QueryTimeout 0 | Select-object  -expandProperty DBServer,DBName
		#$DBNames = Invoke-SQLcmd -ServerInstance $SQLServer -Query $Query -QueryTimeout 0 | out-string 
		#$DBNames = Invoke-SQLcmd -ServerInstance $SQLServer -Query $Query -QueryTimeout 0 
	}
	
   $DBNamesAll = @($DBNamesall + $DBNames)
	
}
$DBNamesAll | Export-Csv -notype .\FoundDBs.csv

