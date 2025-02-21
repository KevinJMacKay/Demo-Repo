## Create Windows Jump box
Launch instance
Windows
t2.micro
Create keypair (Pem) if needed

Edit Network settings
Select your vpc i.e. kmvpc
Select Public Subnet: xx-Primary-Public-A --make sure this is a Public subnet
Auto-assign public IP - Enable
Firewall
Create security group
Name kmvpc-sg
add description: All RDP from myIP 
Inbound rule
Type: rdp
Source: My IP (select from drop down) use http://checkip.amazonaws.com
Description: Allow RDP from MyIP
default settings the rest.

# create via cli

aws ec2 create-security-group --group-name "kmvpc-ec2sg" --description "All RDP from myIP" --vpc-id "vpc-072ad521abd1746ec" 

Use new security group-id in the following commands

aws ec2 authorize-security-group-ingress --group-id "sg-0d32596cfd6ba86fa" --ip-permissions '{"IpProtocol":"tcp","FromPort":3389,"ToPort":3389,"IpRanges":[{"CidrIp":"20.151.82.165/32","Description":"Allow RDP from MyIP"}]}' 

aws ec2 run-instances --image-id "ami-037bb856a23a2f822" --instance-type "t3.micro" --key-name "kmvpc-pemkey" --network-interfaces '{"SubnetId":"subnet-0c1ef3d1c455e14e2","AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["sg-0d32596cfd6ba86fa"]}' --credit-specification '{"CpuCredits":"unlimited"}' --tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"kmvpc-winjump"}]}' --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":false,"EnableResourceNameDnsAAAARecord":false}' --count "1" 


# Connect via RDP
Select new ec2 instance, select Actions, Security, Get Windows Password
Upload private key file
Click Decrypt password

Instance ID i-04d421606934f861e (kmvpc-winjump)
Private IP address
172.19.188.123
Username
Administrator
Password
zT8VKr4)2vLuQ(NnA%k7iU%oIJMEMic$

Select Connect
Download remote desktop file

## Provisioning iSCSI for Windows
https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/mount-iscsi-windows.html

PS C:\Users\Administrator> Start-Service MSiSCSI
PS C:\Users\Administrator> Set-Service -Name msiscsi -StartupType Automatic
PS C:\Users\Administrator> (Get-InitiatorPort).NodeAddress

iqn.1991-05.com.microsoft:ec2amaz-qlp5u62

Install-WindowsFeature Multipath-IO

# Configure iSCSI on the FSx for ONTAP file system

https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/mount-iscsi-windows.html


# FsX File System Build
https://docs.aws.amazon.com/cli/latest/reference/fsx/

Run from default CloudShell terminal (us-east-1)

aws fsx create-file-system /
--file-system-type ONTAP /
--storage-capacity 1024 /
--subnet-ids subnet-057d1384fa649bbb4 /
--storage-type SSD /
--security-group-ids sg-09f81f4688f9c115e /
--ontap-configuration DeploymentType=SINGLE_AZ_1,PreferredSubnetId=subnet-057d1384fa649bbb4,FsxAdminPassword=Desire2Learn,ThroughputCapacity=128 /
--tags Key=Name,Value=kmvpc-fsx-cli

aws fsx describe-file-systems
aws fsx describe-file-systems --file-system-id 

# Update FsX File System
https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/updating-file-system.html

# disable daily backups
aws fsx update-file-system \
    --file-system-id fs-0ccca271344fd0e44 \
    --ontap-configuration AutomaticBackupRetentionDays=0

# FsX SVM Build
aws fsx create-storage-virtual-machine \
    --file-system-id fs-0ccca271344fd0e44\
    --name svm1 \
    --svm-admin-password Desire2Learn \
    --root-volume-security-style NTFS

aws fsx describe-storage-virtual-machines 

svm-068271447a4d43d07

# Add volume - 100GB
aws fsx create-volume \
    --name vol2 \
    --volume-type ONTAP \
    --ontap-configuration JunctionPath=/vol2,SecurityStyle=NTFS,SizeInMegabytes=102400,StorageVirtualMachineId=svm-0937a06db3489bed9,OntapVolumeType=RW,StorageEfficiencyEnabled=true

aws fsx describe-volumes --volume-id fsvol-0407af3aa26d1b70b

# Creating an iSCSI LUN
https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/create-iscsi-lun.html

# Connect to fsxadmin
ssh fsxadmin@172.19.189.55

network interface show

lun create -vserver svm1 -path /vol/vol2/lun1 -size 10G -ostype windows_2008 -space-allocation enabled

-Created a LUN of size 10g (10737418240)

# create igroup - you can add multiple iqn's to an igroup, use comma separated list in -initiator
lun igroup create -vserver svm1 -igroup igroup_1 -initiator iqn.1991-05.com.microsoft:ec2amaz-qlp5u62 -protocol iscsi -ostype windows 

lun igroup show

# create lun mapping 
lun show -- will show lun unmapped
lun mapping create -vserver svm1 -path /vol/vol2/lun1 -igroup igroup_1 -lun-id 1

lun show -- will show lun mapped

lun show -path /vol/vol2/lun1 
lun show -path /vol/vol2/lun1 -fields state,mapped,serial-hex

# iSCSI IP addresses
172.19.189.57, 172.19.189.63

# Mount an iSCSI LUN on the Windows client
https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/mount-iscsi-windows.html#configure-iscsi-on-fsx

Create ps1 file:

#iSCSI IP addresses for Preferred and Standby subnets 
$TargetPortalAddresses = @("172.19.189.57","172.19.189.63") 
                                    
#iSCSI Initator IP Address (Local node IP address) 
$LocaliSCSIAddress = "172.19.188.123" 
                                    
#Connect to FSx for NetApp ONTAP file system 
Foreach ($TargetPortalAddress in $TargetPortalAddresses) { 
New-IscsiTargetPortal -TargetPortalAddress $TargetPortalAddress -TargetPortalPortNumber 3260 -InitiatorPortalAddress $LocaliSCSIAddress 
} 
                                    
#Add MPIO support for iSCSI 
New-MSDSMSupportedHW -VendorId MSFT2005 -ProductId iSCSIBusType_0x9

#Set the MPIO path configuration for new servers to ensure that MPIO is properly configured and visible in the disk properities.
Set-MPIOSetting -NewPathVerificationState Enabled
                                    
#Establish iSCSI connection 
1..8 | %{Foreach($TargetPortalAddress in $TargetPortalAddresses)
{Get-IscsiTarget | Connect-IscsiTarget -IsMultipathEnabled $true -TargetPortalAddress $TargetPortalAddress -InitiatorPortalAddress $LocaliSCSIAddress -IsPersistent $true}}
                                    
#Set the MPIO Policy to Round Robin 
Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy RR 


## Run Powershell Commands from Windows Jump Box

To be able to run FSx PowerShell commands from jumpbox, it needs to be assigned a new role granting fsx command priviledges

# Create new role i.e. kmvpc-fsxadmin-role
Select trusted entity: AWS service
Use case: EC2 (Allows EC2 instances to call AWS services on your behalf.)
Next
Add permissions
Permissions policies
Check "AmazonFSxFullAccess" and "AmazonEC2ReadOnlyAccess"
Role name: "kmvpc-fsxadmin-role"
Description: "Allows EC2 instances to call AWS FSx service on your behalf."
Click Create role

# Create FSx file system

$subnetId = "subnet-057d1384fa649bbb4" - KMVPC-Primary-Private-A
$securityGroupId = "sg-09f81f4688f9c115e" - KMVPC-Primary-Internal-ANY

New-FSXFileSystem -FileSystemType ONTAP -StorageCapacity 1024 -SubnetIds $subnetId -SecurityGroupIds $securityGroupId -OntapConfiguration_DeploymentType SINGLE_AZ_1 -OntapConfiguration_ThroughputCapacity 128

Get-FSXFileSystem -FileSystemId fs-0306a2e68bbda3df3

# Create SVM

New-FSXStorageVirtualMachine -Name kmvpc-svm -FileSystemId fs-0306a2e68bbda3df3 -RootVolumeSecurityStyle NTFS -SvmAdminPassword Desire2Learn

Get-FSXStorageVirtualMachine -StorageVirtualMachineId svm-012b1f1e3aa6ac298

# Create Igroup

$Igroup = "kmvpc-igroup1"
New-NcIgroup -Name $Igroup -Protocol iscsi -Type Windows

# Add Initiators to Igroup

$Initiator1 = (Get-InitiatorPort).NodeAddress
Add-NcIgroupInitiator -Name $Igroup -Initiator $Initiator1 

 Get-NcIgroup

# Create FSx Volume

Import-Module c:\modules\NetApp.ONTAP\NetApp.ONTAP.psd1

$password = ConvertTo-SecureString "Desire2Learn" -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "vsadmin",$password
Connect-NcController 172.19.189.25 -Credential $cred

Get-NcVol (should show the rvm_root volume)

$VolName = "kmvpc_vol5"
$SizeInBytes = 2097152000
$NewVol = New-NcVol `
    -Name $VolName `
    -Size $SizeInBytes `
    -Aggregate 'aggr1' `
    -JunctionPath "/$VolName" `
    -SecurityStyle 'NTFS'

Get-NcVol 

# Use NetApp Powershell to create lun
$LUNPath = "/vol/kmvpc_vol2/lun1"
New-NcLun -Path $LUNPath -Size 100MB -OsType windows

# Map LUN
Add-NcLunMap -Path $LUNPath -InitiatorGroup $Igroup

## Mount new lun to Windows
We need the iscsi endpoint and ec2 instance ip addresses

# run the following
$ec2_id = Get-EC2Instance | Select-Object -ExpandProperty Instances | Select-Object -ExpandProperty InstanceId
$LocaliSCSIAddress = Get-EC2Instance -InstanceId $ec2_id | Select-Object -ExpandProperty Instances | Select-Object -ExpandProperty PrivateIpAddress
$LocaliSCSIAddress

$svm = Get-FSXStorageVirtualMachine
$TargetPortalAddresses = $svm.Endpoints.Iscsi.IpAddresses
$TargetPortalAddresses

# Connect to FSx for NetApp ONTAP file system
Foreach ($TargetPortalAddress in $TargetPortalAddresses) { 
New-IscsiTargetPortal -TargetPortalAddress $TargetPortalAddress -TargetPortalPortNumber 3260 -InitiatorPortalAddress $LocaliSCSIAddress 
} 

# Add MPIO support for iSCSI 
New-MSDSMSupportedHW -VendorId MSFT2005 -ProductId iSCSIBusType_0x9

# Set the MPIO path configuration for new servers to ensure that MPIO is properly configured and visible in the disk properities.
Set-MPIOSetting -NewPathVerificationState Enabled

# Establish iSCSI connection 
1..8 | %{Foreach($TargetPortalAddress in $TargetPortalAddresses)
{Get-IscsiTarget | Connect-IscsiTarget -IsMultipathEnabled $true -TargetPortalAddress $TargetPortalAddress -InitiatorPortalAddress $LocaliSCSIAddress -IsPersistent $true}}
                                    
# Set the MPIO Policy to Round Robin 
Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy RR 

# check disk management for new disk.
Start-Process "diskmgmt.msc"


## Add new lun to existing volume

# Use NetApp Powershell to create lun
$LUNPath = "/vol/kmvpc_vol2/lun2"
New-NcLun -Path $LUNPath -Size 100MB -OsType windows

# Map LUN
Add-NcLunMap -Path $LUNPath -InitiatorGroup $Igroup

# check for mounted disk disk management
Update-HostStorageCache
Get-disk

# Bring disk online and format
$DiskNumber = Get-Disk | Where-Object { $_.PartitionStyle -eq "RAW" } | Select-Object -expandproperty number

Set-Disk -Number $DiskNumber -IsOffline $FALSE
Set-Disk -Number $DiskNumber -IsReadOnly $FALSE

$DriveLetter = "M"
$DriveName = "MyNetAppDrive"
$AllocSize = 65536 
New-Volume -DiskNumber $DiskNumber -DriveLetter $DriveLetter -FriendlyName "$DriveName" -FileSystem NTFS -AllocationUnitSize $AllocSize | Out-Null

## Cleanup all CIS-Lrn resourses

# Volumes
Delete all volumes (you will not be able to delete svm_root)
No final backup required.

# SVM
Delete SVM

# File System
Delete File System
Cannot delete file system while it has storage virtual machines:

# S3
Empty flowlogs bucket
Delete bucket

# JumpBox
Terminate jumpbox

# Security Groups
Delete custom sg i.e. kmvpc-ec2sg

# VPC
update main.tf (comment out your VPC config) and commit PR

Check for errors in the Terraform.

Cleanup as needed.


