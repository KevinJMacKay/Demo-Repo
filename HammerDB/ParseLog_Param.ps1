param (    
[parameter(Mandatory = $false)][string]$Server,	
[parameter(Mandatory = $false)][string]$Database,	
[parameter(Mandatory = $false)][string]$LogFile,
[parameter(Mandatory = $false)][string]$Results
)

#$Results = "C:\DBA_Scripts\HammerDB\HammerDBResults.txt"

#$logfile = "C:\Users\KMACKA~1\AppData\Local\Temp\hammerdb.log"


$endtime = Get-Date -format "dddd MMM dd HH:mm:ss yyyy"
$header = "servername,database,vu,nopm,tpm"

	if (Test-Path $LogFile)
	{
		# Read remote file
		$loglines = (Get-Content $LogFile)
        # Get first occurance of date in log
        $DateLine = Get-Content $LogFile | Select-String -Pattern "Hammerdb Log" | select-object -First 1
        Add-Content -Path $Results "$DateLine"
        Add-Content -Path $Results "$Header"
        		

		# Find lines containing "Test complete" and get it and next 4 lines
		$ResultsLine = Get-Content $LogFile | Select-String -Pattern "Test complete" -AllMatches -Context 0, 3

		foreach ($line in $ResultsLine)
		{
			$NumUsers = ""
			$TPM = ""
			$NOPM = ""

			$found = $line -match ":(?<content>.*) Active Virtual Users"
			if ($found)
			{	
				$NumUsers = $matches['content']
			}

			$found = $line -match "from (?<content>.*) SQL Server"
			if ($found)
			{	
				$TPM = $matches['content']
			}

			$found = $line -match "achieved (?<content>.*) NOPM"
			if ($found)
			{	
				$NOPM = $matches['content']
			}

			Add-Content -Path $Results "$server,$Database,$NumUsers,$NOPM,$TPM"

		}

		Add-Content -Path $Results "Hammerdb Log End @ $endtime`n"
	}
