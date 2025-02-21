param (    
[parameter(Mandatory = $false)][string]$SqlNetworkName, # "FCIA01A"
[parameter(Mandatory = $false)][string]$SqlInstanceName, # "INSTA"
[parameter(Mandatory = $false)][string]$Server, # "LAB1SIOSQL701"
[parameter(Mandatory = $false)][string]$InstanceSize, # "r5.2xlargeA"
[parameter(Mandatory = $false)][string]$StorageType, # "SiosDK_PerfTest"
[parameter(Mandatory = $false)][string]$TestCount, # 3
[parameter(Mandatory = $false)][string]$Duration, # 5
[parameter(Mandatory = $false)][string]$Workload_VUs, # '800 1000 1200'
[parameter(Mandatory = $false)][string]$Allwarehouse,
[parameter(Mandatory = $false)][string]$Rampup
)

Write-Host "Starting Process"
$SqlServerInstance =$SqlNetworkName+"\"+$SqlInstanceName
$PerfMonSet = "HammerDB_PerfTest"
$Results = "C:\Users\kmackaycolo\Documents\$StorageType\HammerDB-$Server-$InstanceSize.txt" 
$AttachmentPath = "C:\Users\kmackaycolo\Documents\$StorageType\Waits-$Server-$InstanceSize.csv"
$Results
$AttachmentPath
$dbname = "Stats"
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
    Invoke-Sqlcmd -ServerInstance $SqlServerInstance -Database  $dbname -InputFile $QueryFile1

    Write-Host "Starting HammerDB"
    Set-Location "C:\DBA_Scripts\HammerDB"

    .\Run_Hammerdb_fci.ps1 `
    -LogFile 'C:\Users\KMACKA~1\AppData\Local\Temp\hammerdb.log' `
    -WorkloadFile 'C:\DBA_Scripts\HammerDB\workload.tcl' `
    -RestorePath 'V:\SQL_Backups' `
    -DataPath 'E:\SQL_Data' `
    -LogPath 'F:\SQL_Logs' `
    -Server $SqlNetworkName `
    -Instance $SqlInstanceName `
    -Database 'Hammerdb_250' `
    -Duration $Duration  `
    -Workload_VUs $Workload_VUs `
    -Results $Results `
    -Allwarehouse $allwarehouse `
    -Rampup $rampup `

    Write-Host "Complete Waits Collection"
    Invoke-Sqlcmd -ServerInstance $SqlServerInstance -Database $dbname -InputFile $QueryFile2

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
Invoke-Sqlcmd   -ServerInstance $SqlServerInstance -Database  $dbname -Query $QueryFmt | Export-CSV $AttachmentPath -NoTypeInformation

Write-Host "Open Results" -ForegroundColor Green
Notepad $Results 
Notepad $AttachmentPath

Set-Location "C:\DBA_Scripts\HammerDB_PerfTest"