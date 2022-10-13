Write-Host "Copy SQL install files from s3"
Import-Module AWSPowerShell -Force;
Copy-S3Object -BucketName d2l-lab-packages -KeyPrefix dba-ISO/2019DEV -LocalFolder C:\DBA_Scripts\Setup_Scripts\2019DEV -force;
Copy-S3Object -BucketName d2l-lab-packages -KeyPrefix dba-ISO/2019 -LocalFolder C:\DBA_Scripts\Setup_Scripts\2019 -force;

Write-Host "Launching SysPrep"
C:\ProgramData\Amazon\EC2-Windows\Launch\Settings\Ec2LaunchSettings.exe

Write-Host "Run cleanup script BEFORE!! running ""Shutdown with Sysprep""" -ForegroundColor Green