Write-Host "Starting Process"
$Server = "LAB1APSQLX466"
$Duration = 2
#$Workload_VUs = '25 50 100 200'
$Workload_VUs = '10'
$Results = 'C:\DBA_Scripts\HammerDB\HammerDBResults_Test2.txt' 
$dbname = "Stats"
$AttachmentPath = "C:\Users\kmackaycolo\Documents\BasicAG_PerfTests\test2.csv"
$Start = (Get-Date).AddDays(-10)

start-sleep -Seconds 5

$End = Get-Date
Write-Host "Get Wait Stats from $Start to $End"
$QueryFmt= @"
Select CollectionTime, WaitType, WaitCount, Percentage From [STATS].[dbo].[WaitsOverTime]
where CollectionTime Between '$Start' AND '$End'
Order by CollectionTime desc, Percentage desc
"@
Write-Host $QueryFmt
Invoke-Sqlcmd   -ServerInstance $Server -Database  $dbname -Query $QueryFmt | Export-CSV $AttachmentPath -NoTypeInformation

Write-Host "Open Results"
Notepad $Results 
Notepad $AttachmentPath
