param (    
	[parameter(mandatory=$false,ValueFromPipeline=$true)][array[]]$SQLServers,
	[Parameter(ParameterSetName='Query')][String]$Query,
	[Parameter(ParameterSetName='QueryFile')][String]$QueryFile,
	[Parameter(ParameterSetName='PowerShellscript')][String]$PowerShellscript,
	[parameter(Mandatory = $false)][switch]$CreateOutput,
	[parameter(Mandatory = $false)][string]$Output=".\output.txt"
	)

process {

    if ($CreateOutput){
	    new-item -type file $output -force
	    }
  
    if (!$Query -AND !$QueryFile -AND !$PowerShellscript){
        Write-Host "No query, queryfile or PowerShell script provided. Please provide one of these variables." -foreground red
        exit
	    }
	
    
    
    if (!$SQLServers){
	    if ((Test-Path  C:\Modules\SQL_Admin.psm1) -eq $FALSE){
		    Write-Host "SQL_Admin.psm1 not found."
		    Exit
		    }
	    Import-Module C:\Modules\SQL_Admin.psm1 -Force
	    Import-Module sqlps -Force
	    cd c:
	
	    $dbinfoJson = Get-dbinfo
	    $Environment = Get-Environment
	    $listeners = $dbinfoJson.datacenters.$environment.listeners.psobject.properties.name
	    foreach ( $listener in $listeners ) {
		    $listenerobject = $dbinfoJson.datacenters.$environment.listeners.$listener
		
		    $AG = $listenerobject.availabilitygroup
		    $Servers = $listenerobject.servers
		    $SQLServers = $SQLServers + $Servers
		    $SQLServers = $SQLServers | select-object -unique | sort-object
		    }
        }
    
    foreach ($SQLServer in $SQLServers){
        $SQLServer=($SQLServer | Out-String).TrimEnd()
        if ($Query){
            Write-Host "Running query against $SQLServer"
            $Results = Invoke-SQLcmd -ServerInstance $SQLServer -Query $Query -QueryTimeout 0 | ft -wrap | out-string
		    Write-Host $Results `n
		    if ($CreateOutput){
			    If ($Results){
				    cd c:
				    Add-content $output ":CONNECT $SQLServer"
				    Add-content $output "$Results"
				    Add-content $output "GO `n"
				    }
			    }
            }
        elseif ($QueryFile){
            $TestPath = Test-Path $QueryFile
            if ($TestPath -eq $False){
                Write-Host "Cannot find query file specified: $QueryFile" -foreground red
                break
                }
            Write-Host "Running queryfile against $SQLServer"
		    $Results = Invoke-SQLcmd -ServerInstance $SQLServer -InputFile $QueryFile -QueryTimeout 0 | ft -wrap | out-string
		    Write-Host $Results `n
		    if ($CreateOutput){
			    If ($Results){
				    cd c:
				    Add-content $output ":CONNECT $SQLServer"
				    Add-content $output "$results `n"
				    Add-content $output "GO `n"
				    }
			    }
            }
		    elseif ($PowerShellscript) {
			    Write-Host "Running PowerShell script against $SQLServer"
			    $Results = Invoke-Command -ComputerName $SQLServer -ScriptBlock { param ($PowerShellScript)
				    Invoke-Expression $PowerShellScript
				    } -ArgumentList $PowerShellScript
			    if ($Results -AND !$CreateOutput){
				    Write-Host $SQLServer
				    Write-Host $Results `n
				    }
			    if ($CreateOutput){
				    cd c:
				    if ($Results){
					    Add-content $output "$SQLServer"
						Add-content $output "$results `n"
					    }
				    }
			    }
        }
}