# SQL Server PBMM Path

#### Requirements (The requirements that must be met regardless of solution)
Data at rest needs to be encrypted by a CMK to meet the requirements of PBMM clients.

#### Preferred Solution (How it should be done, ideally with code examples)
TBD

#### Documented exceptions
TBD

### Current State and Proposed Solution

#### Current State

SQL Servers use EBS and S3 for client data storage. 
- EBS is used as attached storage for SQL servers running on EC2 instances this included operating system (AMI), database data and log files.
- S3 is used to store database backups (IA for 30 days then transitioned to Glacier for 90 days).
- Today EBS and S3 storage is encrypted using AWS KMS

#### Proposed Solution (Theories)

##### IAM roles
Currently we use dedicated IAM roles to allow instances to copy SQL database backups to s3 for x days of storage.
A similar IAM role, but dedicated to the PBMM client (i.e. Canada Schools), will need to be created that gives encrypt/decrypt rights. 
EC2 AMI's are currently encrypted using AWS KMS. PBMM versions of the AMI will need to be created using the required CMK for encryption. 

##### Jenkins
SQL Servers are built using a Jenkins job, one per AWS region using an AMI specific in the sqlinfo.json configuration file.
A PBMM version of the Jenkins job will need to be created that can use the required CMK for that client. Possibly this can be done by one job that has multiple access privileges.  Perhaps this is not needed at all since we store no client data on the c:\ drive of SQL servers. _Confirmation will be needed on this point_.
The Jenkins jobs do add the EBS volumes (database data and logs) that will hold the client data. These volumes will have to be created with encryption based on the client CMK, 
Jenkins may need additional privileges.

##### Powershell 
EBS volume related powershell scripts will have to updated to allow for PBMM encryption. 
ExpandAWSVolume.ps1
ExpandAWSVolume_jenk.ps1
NewAWSVolume.ps1
NewAWSVolume_Jenkins.ps1

##### S3
Dedicated s3 buckets with PBMM CMK applied for database backups.


