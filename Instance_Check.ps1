param (   
	[parameter(Mandatory = $true)][array]$Instance
	)
	
$Domain = (Get-WmiObject Win32_ComputerSystem).Domain

if(($Domain -like "*tor01*") -OR ($Domain -like "*ca3*")){
	$Environment = "colo"
	}
	elseif(($Domain -like "*aas2*") -OR ($Domain -like "*aas1*") -OR ($Domain -like "*aew1*") -OR ($Domain -like "*aue1*") -OR ($Domain -like "*acc1*")){
		$Environment = "aws"
		}
		else{ Write-Host "$Domain not found" -foregoround red
			exit
			}

if ($Environment -eq "colo"){
	$SQLInstance = "db-"+$Instance+",1450"
	$DatabaseCname = "db-"+$Instance
	$Fileshare = "\\fs-"+$Instance+"\"+$Instance
	$Filesharecname = "fs-"+$Instance
	}
	elseif ($Environment -eq "aws"){
		$SQLInstance = "db-"+$Instance
		$DatabaseCname = "db-"+$Instance
		$Fileshare = "\\fs-"+$Instance+"\"+$Instance
		$Filesharecname = "fs-"+$Instance
		}
		else {
			Write-Host "Environment invalid. Current value of environment variable is: $Environment" -foreground red
			}

import-module sqlps
cd c:

Write-Host "`nPerforming checks for $Instance" -background darkgreen
Write-Host "`nTesting database connection ($DatabaseCname)............"
if ((Test-Connection $DatabaseCname -quiet) -eq $TRUE){
	Write-Host "Successfully connected to $DatabaseCname" -foreground green
	$Database = Invoke-SQLCmd -serverinstance $SQLInstance -query "select name from sys.databases where name = '$Instance'" | select -expandproperty name
	if($Database -ne $Instance){
		Write-Host "Unable to find database $Instance" -foreground red
		}
		ELSE {
			$LastLoginQuery = "select top 1 username, utcattemptdate from user_login_attempts order by utcattemptdate desc"
			$LastLogin = Invoke-SQLCmd -serverinstance $SQLInstance -database $Database -query $LastLoginQuery | ft -auto | out-string
			Write-Host "Last successful login to the database:"
			Write-Host $LastLogin
			}
	}
	ELSE {
		Write-Host "Unable to connect to the database server via $DatabaseCname" -foreground red
		}

Write-Host "`nTesting fileshare connection ($Filesharecname)............"
if ((Test-Connection $FileshareCname -quiet) -eq $TRUE){
	Write-Host "Successfully connected to $FileshareCname" -foreground green
	if ((Test-Path $Fileshare) -eq $TRUE){
		Write-Host "Path $Fileshare exists and is accessible."
		Write-Host ""
		}
		ELSE {
			Write-Host "Path $Fileshare is inaccessible or does not exist" -foreground red
			Write-Host ""
			}
	}
	else {
		Write-Host "Unable to connect to the fileshare via $FileshareCname" -foreground red
		}