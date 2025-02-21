
## Terraform - Create vpc

Login to via Okta to lrn-CIS account as Admin
Go to VPC's. You should find the following VPC already created:
CISLRN-vpc
There may be other VPCs there if other CIS members have created them. The name of the VPC should indicate the initials of who owns the vpc.

VPC creation in the Lrn-CIS account is controlled by Terraform. The following repo controls the terraform builds:
github.com/Brightspace/cis-lrncis

Review the Readme.md doc for build instructions.
We will use the "the Simple way" to build our VPC.

Update the .\terraform\modules\account-lrncis\main.tf file as instructed. 
Be sure to use your initials in the "name -prefix" i.e. KMVPC. This prefix will be applied to all resources created by terraform.
This makes it easy to know who owns the resources. 
Commit to draft PR if you want to see the Terraform plan details before proceeding with PR.
Review "Details" of Checks in git hub for "Terraform LrnCIS / terraform plan / Plan (lrn-cis/us-east-1)"
Click Summary on view Terraform plan.
Review plan to see what resources will be created. The last line of the plan should look like:
Plan: 77 to add, 0 to change, 0 to destroy.
 
Return to the main PR page and select "Ready for review"

To approve the PR yourself, check the "Merge without waiting for requirements to be met (bypass branch protections)" box.
Click "Merge pull request"
And Confirm merge

Now that the PR is approved, "Action" must be taken to have Terraform apply the changes.

Go to Actions tab at the top of the page to view the workflows.
The "Merge" of your PR will be in either Working, Queued, Waiting states. 
Once the merge is in the "Waiting" state click to view details. The Terraform plan summary will be at the bottom of this page. 
At the top of the page click "Review deployments"
On the "Review pending deployments" pop-up click check box for "lrn-cis.us-east-1".
You can now click "Approve and deploy" to have Terraform create the requested resources.

Status will change to "In progress" as Terraform does its work. This will take  5-10 minutes to complete.

Once completed, go to the lrn-CIS account in the AWS console to confirm VPC has been created.

# Cost avoidance
Delete NAT Gateways when not in use via AWS console

# VPC Cleanup
To cleanup 
ec2
terminate any ec2 instances

s3
Remove any remaining buckets i.e. flowlogs

│ Error: deleting Amazon S3 (Simple Storage) Bucket (kmvpc1-vpc-flowlogs): BucketNotEmpty: The bucket you tried to delete is not empty
│ 	status code: 409, request id: JRBJDEQBPQTX4RX0, host id: AbAkaDbYI0fAhzm835kkMr0vPYCMggNyv/lyVCu/d5kTrarmbvD4Ahjp4QElmOCY/eG54B9K+Ts=


Error: deleting EC2 Internet Gateway (igw-0f770ab6062bbace9): error detaching EC2 Internet Gateway (igw-0f770ab6062bbace9) from VPC (vpc-072bfe1f2e04730ce): DependencyViolation: Network vpc-072bfe1f2e04730ce has some mapped public address(es). Please unmap those public address(es) before detaching the gateway.


Create new PR with your config in main.tf commentted out (allow for future use).
Approve and Merge PR.
Click "Review deployments"
On the "Review pending deployments" page click check box for "lrn-cis.us-east-1".
You can now click "Approve and deply" to have Terraform remove your vpc.


https://github.com/Brightspace/cis-lrncis/actions/runs/11483163493

## Docs

https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/managing-resources-ontap-apps.html

https://catalog.us-east-1.prod.workshops.aws/workshops/d3e3941a-1044-430f-8178-8e849b754d1d/en-US/01-introduction

# Launch and run Amazon FSx for NetApp ONTAP file systems - AWS Virtual Workshop
https://www.youtube.com/watch?v=PhSIse89AAM

# What’s the Difference Between NFS and CIFS?
https://aws.amazon.com/compare/the-difference-between-nfs-and-cifs/#:~:text=NFS%20uses%20a%20lightweight%20protocol,especially%20in%20high%2Dlatency%20networks.

# AWS Networking Fundamentals
https://www.youtube.com/watch?v=hiKPPy584Mg&t=49s

# Flow Logs
https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-basics.html
https://www.youtube.com/watch?v=pvV5tCXSlr0


## iSCSI on Linux
https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/mount-iscsi-luns-linux.html


## Create Linux Instance 

# Key pair
Create Key pair i.e. km-kp-rsa-pem
EC2 > Key pairs 
    -Key pair type = RSA 
    -Private key file format
        -pem(OpenSSH)
        -ppk(Putty)


# EC2 instance create - from Cloud Shell
aws ec2 run-instances --image-id "ami-06b21ccaeff8cd686" --instance-type "t2.micro" --key-name "km-kp-rsa-ppk" --network-interfaces '{"SubnetId":"subnet-0c3abf53e31a89d20","AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["sg-08fcdc290b6f5c62f"]}' --credit-specification '{"CpuCredits":"standard"}' --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":false,"EnableResourceNameDnsAAAARecord":false}' --count "1" 

# to connect to ec2 instance above
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-to-linux-instance.html

Add security group with inbound rule to allow port 22 (SSH) from "MyIP" (your session IP will be displayed)
Note: this IP changes over time
# Create new Security Group
aws ec2 create-security-group --group-name "SSH-From-MyIP-2" --description "Allows SSH from My IP address only" --vpc-id "vpc-072bfe1f2e04730ce" 

# Add Inbound Rule - needs MyIP, use http://checkip.amazonaws.com
aws ec2 authorize-security-group-ingress --group-id "sg-01153b050999ab488" --ip-permissions '{"FromPort":22,"ToPort":22,"IpProtocol":"tcp","IpRanges":[{"CidrIp":"20.151.82.165/32","description":"My IP - it will change"}]}' 

# Add Outbound Rule
aws ec2 authorize-security-group-egress --group-id "sg-01153b050999ab488" --ip-permissions '{"IpProtocol":"-1","IpRanges":[{"CidrIp":"0.0.0.0/0","description":"All outbound"}]}' 

# modify security groups to add new security group from above "sg-01153b050999ab488"
aws ec2 modify-network-interface-attribute --network-interface-id "eni-080c7a64b7563959a" --groups "sg-08fcdc290b6f5c62f" "sg-01153b050999ab488" 


##### Below is an example of NOT being able to connect to the NFS server port 2049 : 
[ec2-user@ip-10-2-100-193 ~]$ telnet 10.2.100.30 2049
Trying 10.2.100.30...
telnet: connect to address 10.2.100.30: Connection refused

##### Below is an example of SUCCESSFULLY connecting to the NFS server port 2049: 
# get IP from SVM NFS Endpoint
[ec2-user@ip-172-19-188-191 ~]$ telnet 172.19.190.142 2049
Trying 172.19.190.142...
Connected to 172.19.190.142.
Escape character is '^]'.

## FsX File System Build
https://docs.aws.amazon.com/cli/latest/reference/fsx/

aws fsx create-file-system \
    --file-system-type ONTAP \
    --storage-capacity 1024 \
    --subnet-ids subnet-0daeba721164e9d7a \
    --storage-type SSD \
    --security-group-ids sg-08fcdc290b6f5c62f \
    --ontap-configuration DeploymentType=SINGLE_AZ_1,PreferredSubnetId=subnet-0daeba721164e9d7a,FsxAdminPassword=Desire2Learn,ThroughputCapacity=128 \
    --tags Key=Name,Value=kmvpc-fsx-cli

aws fsx describe-file-systems
aws fsx describe-file-systems --file-system-id fs-0163156b0bc3b4e8d

## Update FsX File System
https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/updating-file-system.html

# disable daily backups
aws fsx update-file-system \
    --file-system-id fs-0163156b0bc3b4e8d \
    --ontap-configuration AutomaticBackupRetentionDays=0

## FsX SVM Build

aws fsx create-storage-virtual-machine \
    --file-system-id fs-0163156b0bc3b4e8d \
    --name svm1 \
    --svm-admin-password Desire2Learn \
    --root-volume-security-style UNIX

aws fsx describe-storage-virtual-machines --file-system-id fs-0123456789abcdef0

svm-0203df5023924e7cc

## Add volume - 100GB
aws fsx create-volume \
    --name vol2 \
    --volume-type ONTAP \
    --ontap-configuration JunctionPath=/vol2,SecurityStyle=UNIX,SizeInMegabytes=102400,StorageVirtualMachineId=svm-0203df5023924e7cc,OntapVolumeType=RW,StorageEfficiencyEnabled=true

aws fsx describe-volumes --volume-id vol-0123456789abcdef0

## Creating an iSCSI LUN
https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/create-iscsi-lun.html

ssh fsxadmin@172.19.189.10

lun create -vserver svm1 -path /vol/vol2/lun1 -size 10G -ostype linux -space-allocation enabled

-Created a LUN of size 10g (10737418240)



## Provisioning iSCSI for Linux
https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/mount-iscsi-luns-linux.html

## Create and Connect to Linux instance

# EC2 instance create - from Cloud Shell
aws ec2 run-instances --image-id "ami-06b21ccaeff8cd686" --instance-type "t2.micro" --key-name "km-kp-rsa-ppk" --network-interfaces '{"SubnetId":"subnet-0c3abf53e31a89d20","AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["sg-08fcdc290b6f5c62f"]}' --credit-specification '{"CpuCredits":"standard"}' --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":false,"EnableResourceNameDnsAAAARecord":false}' --count "1" 

## install iSCSI
https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/mount-iscsi-luns-linux.html

sudo yum install -y device-mapper-multipath iscsi-initiator-utils

sudo sed -i 's/node.session.timeo.replacement_timeout = .*/node.session.timeo.replacement_timeout = 5/' /etc/iscsi/iscsid.conf; sudo cat /etc/iscsi/iscsid.conf | grep node.session.timeo.replacement_timeout

sudo service iscsid start

# confirm service is running
sudo systemctl status iscsid.service

# config multipath
sudo mpathconf --enable --with_multipathd y

# get initiator name
sudo cat /etc/iscsi/initiatorname.iscsi

InitiatorName=iqn.1994-05.com.redhat:9b1847764d72

## Configure iSCSI on the FSx for ONTAP file system
https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/mount-iscsi-luns-linux.html#configure-iscsi-on-fsx-ontap

ssh fsxadmin@172.19.189.10

# create igroup - you can add multiple iqn's to an igroup, use comma separated list in -initiator
lun igroup create -vserver svm1 -igroup igroup_1 -initiator iqn.1994-05.com.redhat:9b1847764d72 -protocol iscsi -ostype linux 

lun igroup show

# create lun mapping 
lun show -- will show lun unmapped
lun mapping create -vserver svm1 -path /vol/vol2/lun1 -igroup igroup_1 -lun-id 1

lun show -- will show lun mapped

lun show -path /vol/vol2/lun1 
lun show -path /vol/vol2/lun1 -fields state,mapped,serial-hex

vserver path           serial-hex               state  mapped
------- -------------- ------------------------ ------ ------
svm1    /vol/vol2/lun1 6c574234565d584c5334366b online mapped


network interface show -vserver svm1

            Logical    Status     Network            Current       Current Is
Vserver     Interface  Admin/Oper Address/Mask       Node          Port    Home
----------- ---------- ---------- ------------------ ------------- ------- ----
svm1
            iscsi_1      up/up    172.19.189.38/25   FsxId0163156b0bc3b4e8d-01
                                                                   e0e     true
            iscsi_2      up/up    172.19.189.54/25   FsxId0163156b0bc3b4e8d-02
                                                                   e0e     true
            nfs_smb_management_1
                         up/up    172.19.189.96/25   FsxId0163156b0bc3b4e8d-01
                                                                   e0e     true
3 entries were displayed.


sudo iscsiadm --mode discovery --op update --type sendtargets --portal 172.19.189.38

172.19.189.38:3260,1029 iqn.1992-08.com.netapp:sn.968a96f8955911efb333cfd58cf13719:vs.3
172.19.189.54:3260,1028 iqn.1992-08.com.netapp:sn.968a96f8955911efb333cfd58cf13719:vs.3

sudo iscsiadm --mode node -T iqn.1992-08.com.netapp:sn.968a96f8955911efb333cfd58cf13719:vs.3 --login


Logging in to [iface: default, target: iqn.1992-08.com.netapp:sn.968a96f8955911efb333cfd58cf13719:vs.3, portal: 172.19.189.38,3260]
Logging in to [iface: default, target: iqn.1992-08.com.netapp:sn.968a96f8955911efb333cfd58cf13719:vs.3, portal: 172.19.189.54,3260]
Login to [iface: default, target: iqn.1992-08.com.netapp:sn.968a96f8955911efb333cfd58cf13719:vs.3, portal: 172.19.189.38,3260] successful.
Login to [iface: default, target: iqn.1992-08.com.netapp:sn.968a96f8955911efb333cfd58cf13719:vs.3, portal: 172.19.189.54,3260] successful.

# To assign the block device a friendly name
# edit /etc/multipath.conf via nano 
sudo nano /etc/multipath.conf

# Copy below test with wwid appended to prefix 3600a0980   wwid = 6c574234565d584c5334366b
# add alias name
# use SHIFT INSERT to paste from clipboard into file (https://superuser.com/questions/1262153/how-to-paste-into-nano-from-clipboard)
multipaths {
    multipath {
        wwid 3600a09806c574234565d584c5334366b
        alias myscsilun
    }
}

ls /dev/mapper/myscsilun
# fdisk
sudo fdisk /dev/mapper/myscsilun

cd /dev/mapper
ls
control  myscsilun  myscsilun1

sudo mkfs.ext4 /dev/mapper/myscsilun1

mke2fs 1.46.5 (30-Dec-2021)
Discarding device blocks: done
Creating filesystem with 2621184 4k blocks and 655360 inodes
Filesystem UUID: 7625ec42-d65a-44b8-9906-ca26491fe45d
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

# To mount the LUN on the Linux client

sudo -s
sudo mkdir /scsi_luns/mount_point

sudo mount -t ext4 /dev/mapper/myscsilun1 /scsi_luns/mount_point

sudo chown ec2-user:ec2-user /scsi_luns/mount_point

## test

echo "Hello world!" > /scsi_luns/mount_point/HelloWorld.txt
cat /scsi_luns/mount_point/HelloWorld.txt

Hello world!


# ------------------------------------






## FsX Commands
aws fsx describe-file-systems --file-system-id fs-0d05b3a650188738b
aws fsx describe-file-systems

ssh fsxadmin@file-system-management-endpoint-ip-address
ssh fsxadmin@172.19.189.134
ssh fsxadmin@172.19.190.152
ssh fsxadmin@172.19.189.10

ssh fsxadmin@management.fs-08439e79469d56c9f.fsx.us-east-1.amazonaws.com

# NetAPP commands

network interface show

show-aggregates
security login role show -role fsxadmin -access !none
df -h
volume show
vol show

vol show vol1 -instance
u   u

# linux commands
sudo -s 

mount | grep nfs

NFSENDPOINT="172.19.190.142"
MOUNTPOINT=/myfsx
sudo mkdir ${MOUNTPOINT}
sudo mount -t nfs ${NFSENDPOINT}:/vol1 ${MOUNTPOINT}
sudo chown ec2-user:ec2-user ${MOUNTPOINT}
mount | grep nfs

# Attach instructions
# Open a terminal
# Create a new directory on your EC2 instance (for example, /fsx)
sudo mkdir /fsx2
# Mount your volume
sudo mount -t nfs svm-0512b3cc7bf2c87f8.fs-08439e79469d56c9f.fsx.us-east-1.amazonaws.com:/vol1 /fsx2
sudo chown ec2-user:ec2-user /fsx2

# Unmount
sudo umount /fsx2 -f

DIRNAME=MyDirectory
mkdir ${MOUNTPOINT}/${DIRNAME}
echo "Here is some text for the file." >> ${MOUNTPOINT}/${DIRNAME}/test-file.txt
cat ${MOUNTPOINT}/${DIRNAME}/test-file.text

# to view folder layout
df -h

# Create large files
https://www.baeldung.com/linux/create-large-file#:~:text=Linux%20Command%3A%20truncate%20and%20fallocate,create%20files%20in%20different%20ways.

truncate -s 50G bigfile1.txt
truncate -s 50G bigfile2.txt
truncate -s 50G bigfile3.txt
# view file sizes
ls -lh 



## Cleanup FSx
Delete backup(s)
Delete vol1 (fsvol-0cd457c45c93f56dd)
Delete SVM - svm-0d2b5cd540a96ee6b
Delete km-fsxn (fs-0d05b3a650188738b)


http://checkip.amazonaws.com


Mike 
https://desire2learn.atlassian.net/wiki/spaces/~5a0c620544f6d361ab0c4bef/pages/3644588511/FSxN+Deployment+Procedure

[ec2-user@ip-172-19-188-150 ~]$ df -h
Filesystem            Size  Used Avail Use% Mounted on
devtmpfs              4.0M     0  4.0M   0% /dev
tmpfs                 475M     0  475M   0% /dev/shm
tmpfs                 190M  464K  190M   1% /run
/dev/xvda1            8.0G  1.6G  6.4G  20% /
tmpfs                 475M     0  475M   0% /tmp
/dev/xvda128           10M  1.3M  8.7M  13% /boot/efi
tmpfs                  95M     0   95M   0% /run/user/1000
172.19.190.142:/vol1  973G  113G  861G  12% /fsx
# run as root in shell
[ec2-user@ip-172-19-188-150 ~]$ sudo -s

# view folder permissions
[root@ip-172-19-188-150 ec2-user]# ls -ld /fsx
drwxrwxrwx. 2 root root 4096 Oct 25 13:41 /fsx

d - directory
rwx - read write execute user permissions
rwx - group permissions
rwx - Other permissions


┌─────────── file (not a directory)
|┌─────────── read-write (no execution) permissions for the owner
|│  ┌───────── read-only permissions for the group
|│  │  ┌─────── read-only permissions for others
|│  │  │     ┌── number of hard links
|│  │  │     │   ┌── owner
|│  │  │     │   │     ┌── user group
|│  │  │     │   │     │          ┌── file size in bytes
|│  │  │     │   │     │          │    ┌── last modified on
|│  │  │     │   │     │          │    │                ┌── filename
-rw-r--r--   3 fjones editors    30405 Mar  2 12:52  edition-32

# ummount volume
[root@ip-172-19-188-150 ec2-user]# umount /fsx
[root@ip-172-19-188-150 ec2-user]# ls -ld /fsx
drwxr-xr-x. 2 root root 6 Oct 25 18:22 /fsx

# change owner
[root@ip-172-19-188-150 ec2-user]# sudo chown ec2-user:ec2-user /fsx

# mount volume
[root@ip-172-19-188-150 ec2-user]# sudo mount -t nfs svm-0512b3cc7bf2c87f8.fs-08439e79469d56c9f.fsx.us-east-1.amazonaws.com:/vol1 /fsx
[root@ip-172-19-188-150 ec2-user]# df -h
Filesystem            Size  Used Avail Use% Mounted on
devtmpfs              4.0M     0  4.0M   0% /dev
tmpfs                 475M     0  475M   0% /dev/shm
tmpfs                 190M  464K  190M   1% /run
/dev/xvda1            8.0G  1.6G  6.4G  20% /
tmpfs                 475M     0  475M   0% /tmp
/dev/xvda128           10M  1.3M  8.7M  13% /boot/efi
tmpfs                  95M     0   95M   0% /run/user/1000
172.19.190.142:/vol1  973G  113G  861G  12% /fsx

# still having permission issues
[root@ip-172-19-188-150 ec2-user]# cd /fsx
bash: cd: /fsx: Permission denied
[root@ip-172-19-188-150 ec2-user]# ls -ld /fsx
drwxrwxrwx. 2 root root 4096 Oct 25 13:41 /fsx
[root@ip-172-19-188-150 ec2-user]# ls -l
total 0
[root@ip-172-19-188-150 ec2-user]# sudo chown ec2-user:ec2-user /fsx
chown: changing ownership of '/fsx': Operation not permitted

# view logs
[root@ip-172-19-188-150 ec2-user]# ls -ltr /var/log
total 1364
drwxr-x---. 2 root   root                 6 Jun 12 22:04 sssd
-rw-------. 1 root   root                 0 Oct 10 21:22 tallylog
drwx------. 2 root   root                 6 Oct 10 21:22 private
-rw-rw----. 1 root   utmp                 0 Oct 10 21:22 btmp
lrwxrwxrwx. 1 root   root                39 Oct 10 21:22 README -> ../../usr/share/doc/systemd/README.logs
drwxr-sr-x+ 3 root   systemd-journal     46 Oct 25 17:37 journal
drwx------. 2 root   root                23 Oct 25 17:37 audit
drwxr-xr-x. 2 root   root                18 Oct 25 17:37 sa
drwxr-xr-x. 3 root   root                17 Oct 25 17:37 amazon
-rw-r-----. 1 root   adm               3736 Oct 25 17:38 cloud-init-output.log
-rw-r-----. 1 root   adm             149603 Oct 25 17:38 cloud-init.log
-rw-r--r--. 1 root   root              2359 Oct 25 17:38 hawkey.log
drwxr-x---. 2 chrony chrony              72 Oct 25 17:38 chrony
-rw-r--r--. 1 root   root             83528 Oct 25 17:38 dnf.rpm.log
-rw-r--r--. 1 root   root            871256 Oct 25 17:38 dnf.librepo.log
-rw-r--r--. 1 root   root            267985 Oct 25 17:38 dnf.log
-rw-rw-r--. 1 root   utmp              3072 Oct 25 18:22 wtmp
-rw-rw-r--. 1 root   utmp            292292 Oct 25 18:22 lastlog

# show last 10 logins
[root@ip-172-19-188-150 ec2-user]# last -10
ec2-user pts/1        20.151.82.165    Fri Oct 25 18:22   still logged in
ec2-user pts/0        20.151.82.165    Fri Oct 25 17:45   still logged in
reboot   system boot  6.1.112-122.189. Fri Oct 25 17:37   still running
wtmp begins Fri Oct 25 17:37:50 2024

# connected to svm
FsxId08439e79469d56c9f::> vol show
Vserver   Volume       Aggregate    State      Type       Size  Available Used%
--------- ------------ ------------ ---------- ---- ---------- ---------- -----
kmvpc-svm kmvpc_svm_root
                       aggr1        online     RW          1GB    972.3MB    0%
kmvpc-svm vol1         aggr1        online     RW          1TB    860.6GB    0%
2 entries were displayed.

FsxId08439e79469d56c9f::vserver export-policy> show
Vserver          Policy Name
---------------  -------------------
kmvpc-svm        default
kmvpc-svm        fsx-root-volume-policy
2 entries were displayed.

FsxId08439e79469d56c9f::vserver export-policy> vol show vol1
Vserver   Volume       Aggregate    State      Type       Size  Available Used%
--------- ------------ ------------ ---------- ---- ---------- ---------- -----
kmvpc-svm vol1         aggr1        online     RW          1TB    860.6GB    0%

# view policy on the vol1 instance
FsxId08439e79469d56c9f::vserver export-policy> vol show vol1 -instance

                                      Vserver Name: kmvpc-svm
                                       Volume Name: vol1
                                    Aggregate Name: aggr1
     List of Aggregates for FlexGroup Constituents: aggr1
                                   Encryption Type: none
                  List of Nodes Hosting the Volume: FsxId08439e79469d56c9f-01
                                       Volume Size: 1TB
                                Volume Data Set ID: 1026
                         Volume Master Data Set ID: 2162630556
                                      Volume State: online
                                      Volume Style: flex
                             Extended Volume Style: flexvol
                           FlexCache Endpoint Type: none
                            Is Cluster-Mode Volume: true
                             Is Constituent Volume: false
                     Number of Constituent Volumes: -
                                     Export Policy: default
                                           User ID: -
                                          Group ID: -
# here is the issue. Vol was create with ntfs security and should have been UNIX style
                                    Security Style: ntfs
                                  UNIX Permissions: ------------
###
                                     Junction Path: /vol1
                              Junction Path Source: RW_volume
                                   Junction Active: true
                            Junction Parent Volume: kmvpc_svm_root
                                           Comment:
                                    Available Size: 860.6GB
                                   Filesystem Size: 1TB
                           Total User-Visible Size: 972.8GB
                                         Used Size: 340KB
                                   Used Percentage: 0%
              Volume Nearly Full Threshold Percent: 95%
                     Volume Full Threshold Percent: 98%
                                  Maximum Autosize: 1.20TB
                                  Minimum Autosize: 1TB
                Autosize Grow Threshold Percentage: 95%
              Autosize Shrink Threshold Percentage: 50%
                                     Autosize Mode: off
                          Total User Visible Files: 31876709
                           User Visible Files Used: 97
                         Space Guarantee in Effect: true
                               Space SLO in Effect: true
                                         Space SLO: none
                             Space Guarantee Style: none
Press <space> to page down, <return> for next line, or 'q' to quit...

FsxId08439e79469d56c9f::vserver export-policy>
FsxId08439e79469d56c9f::vserver export-policy>
FsxId08439e79469d56c9f::vserver export-policy> vol modify -volume vol1 -
    -vserver                             -size
    -state                               -policy
    -user                                -group
    -security-style                      -unix-permissions
    -comment                             -space-nearly-full-threshold-percent
    -space-full-threshold-percent        -max-autosize
    -min-autosize                        -autosize-grow-threshold-percent
    -autosize-shrink-threshold-percent   -autosize-mode
    -autosize-reset                      -files
    -space-slo                           -space-guarantee
    -fractional-reserve                  -snapdir-access
    -percent-snapshot-space              -snapshot-policy
    -language                            -foreground
    -nvfail                              -dr-force-nvfail
    -filesys-size-fixed                  -extent-enabled
    -space-mgmt-try-first                -read-realloc
    -sched-snap-name                     -qos-policy-group
    -qos-adaptive-policy-group           -caching-policy
    -vserver-dr-protection               -is-space-reporting-logical
    -is-space-enforcement-logical        -tiering-policy
    -tiering-object-tags                 -anti-ransomware-state
    -granular-data                       -snapshot-locking-enabled
    -is-large-size-enabled


# can't change security type
FsxId08439e79469d56c9f::vserver export-policy> vol modify -volume vol1 -u
    -user             -unix-permissions

FsxId08439e79469d56c9f::vserver export-policy> vol modify -volume vol1 -unix-permissions 777

Error: command failed: You cannot set UNIX permissions for "ntfs" security style. You can set UNIX permissions only for "unix" and "mixed" security styles.

# special diagnostic command - Thanks Mike :)
FsxId08439e79469d56c9f::vserver export-policy> set d

Warning: These diagnostic commands are for use by NetApp personnel only.
Do you want to continue? {y|n}: y

FsxId08439e79469d56c9f::vserver export-policy*> show default -instance

    Vserver: kmvpc-svm
Policy Name: default
  Policy ID: 12884901889

FsxId08439e79469d56c9f::vserver export-policy*> ?
  access-cache>               The access-cache directory
  cache>                      Manage the export-policy cache
  check-access                Given a Volume And/or a Qtree, Check to See If the Client Is Allowed Access
  config-checker>             The config-checker directory
  copy                        Copy an export policy
  create                      Create a rule set
  delete                      Delete a rule set
  netgroup>                   The netgroup directory
  rename                      Rename an export policy
  rule>                       Manage export rules
  show                        Display a list of rule sets

FsxId08439e79469d56c9f::vserver export-policy*> rule show
             Policy          Rule    Access   Client                RO
Vserver      Name            Index   Protocol Match                 Rule
------------ --------------- ------  -------- --------------------- ---------
kmvpc-svm    default         1       any      0.0.0.0/0             any
kmvpc-svm    fsx-root-volume-policy
                             1       any      0.0.0.0/0             any
2 entries were displayed.

# exit diags mode
FsxId08439e79469d56c9f::vserver export-policy*> set admin

FsxId08439e79469d56c9f::vserver export-policy> rule show
             Policy          Rule    Access   Client                RO
Vserver      Name            Index   Protocol Match                 Rule
------------ --------------- ------  -------- --------------------- ---------
kmvpc-svm    default         1       any      0.0.0.0/0             any
kmvpc-svm    fsx-root-volume-policy
                             1       any      0.0.0.0/0             any
2 entries were displayed.

FsxId08439e79469d56c9f::vserver export-policy> quit
Goodbye


Connection to management.fs-08439e79469d56c9f.fsx.us-east-1.amazonaws.com closed.
[root@ip-172-19-188-150 ec2-user]# df -h
Filesystem            Size  Used Avail Use% Mounted on
devtmpfs              4.0M     0  4.0M   0% /dev
tmpfs                 475M     0  475M   0% /dev/shm
tmpfs                 190M  464K  190M   1% /run
/dev/xvda1            8.0G  1.6G  6.4G  20% /
tmpfs                 475M     0  475M   0% /tmp
/dev/xvda128           10M  1.3M  8.7M  13% /boot/efi
tmpfs                  95M     0   95M   0% /run/user/1000
172.19.190.142:/vol1  973G  113G  861G  12% /fsx

# created new volume with unix permission
# mounted new vol to /fsx2
[root@ip-172-19-188-150 ec2-user]# sudo mount -t nfs svm-0512b3cc7bf2c87f8.fs-08439e79469d56c9f.fsx.us-east-1.amazonaws.com:/vol2 /fsx2
[root@ip-172-19-188-150 ec2-user]# df -h
Filesystem                                                                    Size  Used Avail Use% Mounted on
devtmpfs                                                                      4.0M     0  4.0M   0% /dev
tmpfs                                                                         475M     0  475M   0% /dev/shm
tmpfs                                                                         190M  464K  190M   1% /run
/dev/xvda1                                                                    8.0G  1.6G  6.4G  20% /
tmpfs                                                                         475M     0  475M   0% /tmp
/dev/xvda128                                                                   10M  1.3M  8.7M  13% /boot/efi
tmpfs                                                                          95M     0   95M   0% /run/user/1000
172.19.190.142:/vol1                                                          973G  113G  861G  12% /fsx
svm-0512b3cc7bf2c87f8.fs-08439e79469d56c9f.fsx.us-east-1.amazonaws.com:/vol2   19M  192K   19M   1% /fsx2
# tried accessing folder and creating sub directory...success as root!
[root@ip-172-19-188-150 ec2-user]# cd /fsx2
[root@ip-172-19-188-150 fsx2]# ls
[root@ip-172-19-188-150 fsx2]# mkdir myfolder
[root@ip-172-19-188-150 fsx2]# ls
myfolder
# exit root
exit

# tried accessing folder and creating sub directory...success as ec2-user
[ec2-user@ip-172-19-188-150 ~]$ ls
[ec2-user@ip-172-19-188-150 ~]$ cd /fsx2
# success
[ec2-user@ip-172-19-188-150 fsx2]$ ls
[ec2-user@ip-172-19-188-150 fsx2]$ mkdir myfolder
mkdir: cannot create directory ‘myfolder’: Permission denied
# still can't create sub directory, checking owner permissions
[ec2-user@ip-172-19-188-150 fsx2]$ ls -ld
drwxr-xr-x. 2 root root 4096 Oct 25 18:54 .
# changing owner:group to ec2-user:ec2-user
[ec2-user@ip-172-19-188-150 fsx2]$ sudo chown ec2-user:ec2-user /fsx2
[ec2-user@ip-172-19-188-150 fsx2]$ ls -ld
drwxr-xr-x. 2 ec2-user ec2-user 4096 Oct 25 18:54 .
[ec2-user@ip-172-19-188-150 fsx2]$ ls
[ec2-user@ip-172-19-188-150 fsx2]$ mkdir myfolder
[ec2-user@ip-172-19-188-150 fsx2]$ ls
myfolder
# success
