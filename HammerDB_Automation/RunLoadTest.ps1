Write-Host "Starting Process"
$Server = "LAB1APSQLX466"
$TestCount = 3
$Duration = 5
$Workload_VUs = '25 50 100 200'
#$Workload_VUs = '1'
$PerfMonSet = "HammerDB_PerfTest"
$Results = 'C:\Users\kmackaycolo\Documents\BasicAG_PerfTests\HammerDB_LAB1APSQLX466_2x.txt' 
$dbname = "Stats"
$AttachmentPath = "C:\Users\kmackaycolo\Documents\BasicAG_PerfTests\Waits_LAB1APSQLX466_2x.csv"
$QueryFile1 = "C:\DBA_Scripts\HammerDB_PerfTest\GetWaits_Step1.sql"
$QueryFile2 = "C:\DBA_Scripts\HammerDB_PerfTest\GetWaits_Step2.sql"
$Start = (Get-Date)
$Count = 1

While ($Count -le $TestCount) {
    Write-Host "Start Perfmon" -ForegroundColor Green
    Invoke-Command -ComputerName $Server -ScriptBlock {
    Param ($PerfMonSet)
    if ((Get-SMPerformanceCollector -CollectorName $PerfMonSet) -eq "Running") {
        Write-Host "Perfmon already running. Stopping Perfmon!" -ForegroundColor Yellow
        Stop-SMPerformanceCollector -CollectorName $PerfMonSet
        Start-Sleep -Seconds 5
        }
        Start-SMPerformanceCollector -CollectorName $PerfMonSet
    } -ArgumentList $PerfMonSet

    Write-Host "Start Waits Collection"
    Invoke-Sqlcmd -ServerInstance $Server -Database  $dbname -InputFile $QueryFile1

    Write-Host "Starting HammerDB"
    Set-Location "C:\DBA_Scripts\HammerDB"

    .\Run_Hammerdb.ps1 `
    -LogFile 'C:\Users\KMACKA~1\AppData\Local\Temp\hammerdb.log' `
    -WorkloadFile 'C:\DBA_Scripts\HammerDB\workload.tcl' `
    -RestorePath 'V:\SQL_Backups' `
    -DataPath 'E:\SQL_Data' `
    -LogPath 'F:\SQL_Logs' `
    -Server $Server `
    -Database 'Hammerdb_250' `
    -Duration $Duration  `
    -Workload_VUs $Workload_VUs `
    -Results $Results `

    Write-Host "Complete Waits Collection"
    Invoke-Sqlcmd -ServerInstance $Server -Database $dbname -InputFile $QueryFile2

    $Count = $Count + 1
}

Invoke-Command -ComputerName $Server -ScriptBlock { Param ($PerfMonSet)
    if ((Get-SMPerformanceCollector -CollectorName $PerfMonSet) -eq "Running") {
        Write-Host "Stopping Perfmon!" -ForegroundColor Yellow
        Stop-SMPerformanceCollector -CollectorName $PerfMonSet
        }
} -ArgumentList $PerfMonSet

Start-Sleep -Seconds 5
$End = Get-Date

Write-Host "Get Wait Stats from $Start to $End"
$QueryFmt= @"
Select CollectionTime, WaitType, WaitCount, Percentage From [STATS].[dbo].[WaitsOverTime]
where CollectionTime Between '$Start' AND '$End'
Order by CollectionTime desc, Percentage desc
"@
Invoke-Sqlcmd   -ServerInstance $Server -Database  $dbname -Query $QueryFmt | Export-CSV $AttachmentPath -NoTypeInformation

Write-Host "Open Results" -ForegroundColor Green
Notepad $Results 
Notepad $AttachmentPath

Set-Location "C:\DBA_Scripts\HammerDB_PerfTest"