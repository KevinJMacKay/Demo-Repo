$LogFile = "C:\temp\convert\log_dbatest2.txt"

Start-Transcript -Path $LogFile

#Check to see if database version has been updated since last run
$ReportServer = 'db-dbatest1'
$ReportDatabase = 'SCT_Reports'
$SourceServer = 'db-dbatest2'
$SourceDatabase = 'dbatest2'

# Get Source Database Build Version
$GetSourceVersion = "SELECT [Version] FROM PRODUCT_VERSION WHERE [Key] = 'Current'"
$SourceVersion = Invoke-Sqlcmd -ServerInstance $SourceServer -Database $SourceDatabase -Query $GetSourceVersion
$SourceVersion = $SourceVersion.Version.Trim()
Write-Host "SourceVersion: $SourceVersion"

# Get Report Database Build Version
$GetReportVersion = "SELECT TOP 1 BuildVersion FROM [dbo].[Sct_Report_Summary] WHERE BuildVersion is not null ORDER BY ImportDate DESC;"
$ReportVersion = Invoke-Sqlcmd -ServerInstance $ReportServer -Database $ReportDatabase -Query $GetReportVersion
$ReportVersion = $ReportVersion.BuildVersion.Trim()
Write-Host "ReportVersion: $ReportVersion"

if ($SourceVersion -ne $ReportVersion) { 

    <#Copy needed files
    $FilePath = "C:\temp\convert"
    $LogicFilesNeeded = @("SCT_Import_dbatest2-dbo.ps1", "SCT_Import_dbatest2-activity.ps1", "SCT_Import_dbatest2_lor-dbo.ps1",`
    "input_dbatest2-dbo.csv", "input_dbatest2-activity.csv", "input_dbatest2_lor-dbo.csv", `
    "project_dbatest2-dbo.scts", "project_dbatest2-activity.scts", "project_dbatest2_lor-dbo.scts")
    Write-Host "Copying needed files`:"
    foreach ($LogicFile in $LogicFilesNeeded) {
        $LocalFilePath = [System.IO.Path]::Combine($FilePath, $LogicFile)
        $GetS3objectParams = @{
            BucketName = "d2l-lab-packages"
            Key        = "dba-scripts/Tools/dba-scratch/postgres/SCT_Report/$LogicFile"
            LocalFile  = "$LocalFilePath"
            Region     = "us-east-1"
        }
        Copy-S3Object @GetS3objectParams
    }
    #>
    # Define the command to run AWS Schema Conversion Tool
    $Main_dbo = '"c:\Program Files\AWS Schema Conversion Tool\app\RunSCTBatch.cmd" --pathtoscts "c:\temp\convert\project_dbatest2-dbo.scts"'
    $Main_activity = '"c:\Program Files\AWS Schema Conversion Tool\app\RunSCTBatch.cmd" --pathtoscts "c:\temp\convert\project_dbatest2-activity.scts"'
    $LOR_dbo = '"c:\Program Files\AWS Schema Conversion Tool\app\RunSCTBatch.cmd" --pathtoscts "c:\temp\convert\project_dbatest2_lor-dbo.scts"'
    
    # Execute the Main_dbo
    try {
        Write-Host "AWS Schema Conversion Tool starting: Main_dbo."
        Invoke-Expression "cmd.exe /c '$Main_dbo'"
        Write-Host "AWS Schema Conversion Tool executed successfully."

        Write-Host "Starting Import"
        C:\temp\convert\SCT_Import_dbatest2-dbo.ps1
    }
    catch {
        Write-Host "Error executing AWS Schema Conversion Tool: $_"
    }
    # Execute the Main_activity
    try {
        Write-Host "AWS Schema Conversion Tool starting: Main_activity."
        Invoke-Expression "cmd.exe /c '$Main_activity'"
        Write-Host "AWS Schema Conversion Tool executed successfully."

        Write-Host "Starting Import"
        C:\temp\convert\SCT_Import_dbatest2-activity.ps1
    }
    catch {
        Write-Host "Error executing AWS Schema Conversion Tool: $_"
    }
    # Execute the LOR_dbo
    try {
        Write-Host "AWS Schema Conversion Tool starting: LOR_dbo."
        Invoke-Expression "cmd.exe /c '$LOR_dbo'"
        Write-Host "AWS Schema Conversion Tool executed successfully."

        Write-Host "Starting Import"
        C:\temp\convert\SCT_Import_dbatest2_lor-dbo.ps1
    }
    catch {
        Write-Host "Error executing AWS Schema Conversion Tool: $_"
    }

}
else {
    Write-Host "No changes detected in database build version."
}

Stop-Transcript