Write-Host "Download and install AWSTools And SDKForNet"
if((Test-Path "C:\DBA_Scripts") -eq $FALSE){mkdir C:\DBA_Scripts};
Invoke-WebRequest -Uri "http://sdk-for-net.amazonwebservices.com/latest/AWSToolsAndSDKForNet.msi" -OutFile "C:\DBA_Scripts\AWSTools.msi"
C:\DBA_Scripts\AWSTools.msi
pause
Write-Host "Download and install AWSCLI"
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
pause
Write-Host "Download and install PV Driver"
invoke-webrequest https://s3.amazonaws.com/ec2-windows-drivers-downloads/AWSPV/Latest/AWSPVDriver.zip -outfile C:\DBA_Scripts\pv_driver.zip 
expand-archive C:\DBA_Scripts\pv_driver.zip -DestinationPath C:\DBA_Scripts\pv_drivers
C:\DBA_Scripts\pv_drivers\.\install.ps1 -Quiet -NoReboot -VerboseLogging
reg query HKLM\SOFTWARE\Amazon\PVDriver
pause
Write-Host "Set PageFile Size"
$computersys = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges;
$computersys.AutomaticManagedPagefile = $False;
$computersys.Put();
$pagefile = Get-WmiObject -Query "Select * From Win32_PageFileSetting Where Name like '%pagefile.sys'";
$pagefile.InitialSize = 2048;
$pagefile.MaximumSize = 4096;
$pagefile.Put();

Write-Host "Restart-Computer now." -ForegroundColor Green