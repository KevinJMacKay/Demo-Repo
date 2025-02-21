#https://docs.aws.amazon.com/powershell/latest/reference/

Get-DMSMigrationProject



Get-DMSEndpoint `
-Filter @( @{name='endpoint-arn'; values="arn:aws:dms:us-east-1:273050575919:endpoint:B7AQMBQLTFC4VG4L4QFJ3HSJ3Q"})

Edit-DMSEndpoint `
-EndpointArn "arn:aws:dms:us-east-1:273050575919:endpoint:B7AQMBQLTFC4VG4L4QFJ3HSJ3Q" `
-ServerName "172.19.12.133" 

Test-DMSConnection `
-ReplicationInstanceArn "arn:aws:dms:us-east-1:273050575919:rep:6L3UHR47FX7PJMFS5PB36CZMH66UI4RLA4KFDLY" `
-EndpointArn "arn:aws:dms:us-east-1:273050575919:endpoint:B7AQMBQLTFC4VG4L4QFJ3HSJ3Q"

#to view status of endpoint after "New-DMSEndpoint"/"Edit-DMSEndpoint"/Test-DMSConnection:
Get-DMSConnection -Filter @( @{name='endpoint-arn'; values="arn:aws:dms:us-east-1:273050575919:endpoint:B7AQMBQLTFC4VG4L4QFJ3HSJ3Q"})



arn:aws:dms:us-east-1:273050575919:migration-project:IIOOZQGQHJH4RMSR5XPZAJ4ZKY

Get-DMSMigrationProject -Filter @( @{name="MigrationProjectName"; values="spla-dbatest1"})

Get-DMSMigrationProject | where-object MigrationProjectArn -eq "arn:aws:dms:us-east-1:273050575919:migration-project:IIOOZQGQHJH4RMSR5XPZAJ4ZKY"


$param1 = @"
[
{ 
  "DataProviderIdentifier": "arn:aws:dms:us-east-1:273050575919:data-provider:5NB6WZ572VHAFFVWLKK2BZD2VE", 
  "SecretsManagerSecretId": "arn:aws:secretsmanager:us-east-1:273050575919:secret:spla-sql-server-secret-zFKAAp", 
  "SecretsManagerAccessRoleArn": "arn:aws:iam::273050575919:role/spla-secrets-manager-role" 
} 
  ]
"@
$param2 = @"
[
{
    "DataProviderIdentifier": "arn:aws:dms:us-east-1:273050575919:data-provider:4FUPSTH6MZBLJD53PJW6SMT7WA",
    "SecretsManagerSecretId": "arn:aws:secretsmanager:us-east-1:273050575919:secret:spla-postgresql-secret-qulUzU",
    "SecretsManagerAccessRoleArn": "arn:aws:iam::273050575919:role/spla-secrets-manager-role"
  }
]
"@

New-DMSMigrationProject `
-MigrationProjectName "spla-dbatest1-2" `
-Description "spla-dbatest1-2" `
-InstanceProfileIdentifier "arn:aws:dms:us-east-1:273050575919:instance-profile:BQCVHKJVAFF2HNZ4WLU7M5UHSU" `
-SchemaConversionApplicationAttributes_S3BucketPath "s3://dba-spla-s3-bucket" `
-SchemaConversionApplicationAttributes_S3BucketRoleArn "arn:aws:iam::273050575919:role/spla-sc-s3-role" `
-SourceDataProviderDescriptor  ($param1 | convertfrom-json) `
-TargetDataProviderDescriptor  ($param2 | convertfrom-json)


#------------------------------

.\bmx_devlms.ps1



New-DMSReplicationInstance `
    -ReplicationInstanceIdentifier "my-replication-instance" `
    -ReplicationInstanceClass "dms.r5.large" `
    -AllocatedStorage 100 `
    -EngineVersion "3.4.6" `
    -VpcSecurityGroupId "sg-0123456789abcdef0" `
    -ReplicationSubnetGroupIdentifier "my-subnet-group" `
    -AvailabilityZone "us-east-1a" `
    -PubliclyAccessible $true `
    -MultiAZ $false `
    -Tags @(@{Key="Name";Value="dbaReplicationInstance"})

$replicationInstanceParams = @{
  ReplicationInstanceIdentifier    = "dba-replication-instance"
  ReplicationInstanceClass         = "dms.c5.large"
  AllocatedStorage                 = 50
  EngineVersion                    = "3.5.2"
  VpcSecurityGroupId               = "sg-09cda4e0105e9800a"
  ReplicationSubnetGroupIdentifier = "spla-babelfish-migration-testing"
  AvailabilityZone                 = "us-east-1b"
  PubliclyAccessible               = $true
  MultiAZ                          = $false
  Tags                             = @(@{Key = "Name"; Value = "MyReplicationInstance" })
}

New-DMSReplicationInstance @replicationInstanceParams

Get-DMSReplicationInstance -Filter @( @{name='replication-instance-arn'; values="arn:aws:dms:us-east-1:273050575919:rep:WX7VKVGEHRDH3ENEH24VLOABDA"})


AllocatedStorage                      : 50
AutoMinorVersionUpgrade               : True
AvailabilityZone                      : us-east-1b
DnsNameServers                        :
EngineVersion                         : 3.5.2
FreeUntil                             : 1/1/0001 12:00:00 AM
InstanceCreateTime                    : 2/22/2024 8:02:49 PM
KmsKeyId                              : arn:aws:kms:us-east-1:273050575919:key/dfd074e2-ff94-441a-b1b0-4e8ce27b0f86
MultiAZ                               : False
NetworkType                           : IPV4
PendingModifiedValues                 : Amazon.DatabaseMigrationService.Model.ReplicationPendingModifiedValues
PreferredMaintenanceWindow            : tue:09:09-tue:09:39
PubliclyAccessible                    : True
ReplicationInstanceArn                : arn:aws:dms:us-east-1:273050575919:rep:6L3UHR47FX7PJMFS5PB36CZMH66UI4RLA4KFDLY
ReplicationInstanceClass              : dms.c5.large
ReplicationInstanceIdentifier         : spla-migration-testing-replicationinstance1
ReplicationInstanceIpv6Addresses      : {}
ReplicationInstancePrivateIpAddresses : {172.19.20.10}
ReplicationInstancePublicIpAddresses  : {34.202.65.226}
ReplicationInstanceStatus             : available
ReplicationSubnetGroup                : Amazon.DatabaseMigrationService.Model.ReplicationSubnetGroup
SecondaryAvailabilityZone             :
VpcSecurityGroups                     : {sg-09cda4e0105e9800a}


New-DMSEndpoint `
-EndpointIdentifier "dbatest1-aug21" `
-EndpointType "source" `
-EngineName "sqlserver" `
-Username "dms_user" `
-Password "Desire2Learn" `
-ServerName "172.19.12.26" `
-Port "1433" `
-DatabaseName "dbatest1" `
-SslMode "require"

arn:aws:dms:us-east-1:273050575919:endpoint:5RBINPU5FFEBRAKDSZRFO4QR7E

Get-DMSEndpoint `
-Filter @( @{name='endpoint-arn'; values="arn:aws:dms:us-east-1:273050575919:endpoint:5RBINPU5FFEBRAKDSZRFO4QR7E"})


Test-DMSConnection `
-ReplicationInstanceArn "arn:aws:dms:us-east-1:273050575919:rep:6L3UHR47FX7PJMFS5PB36CZMH66UI4RLA4KFDLY" `
-EndpointArn "arn:aws:dms:us-east-1:273050575919:endpoint:5RBINPU5FFEBRAKDSZRFO4QR7E"

Get-DMSConnection -Filter @( @{name='endpoint-arn'; values="arn:aws:dms:us-east-1:273050575919:endpoint:5RBINPU5FFEBRAKDSZRFO4QR7E"})



#------------------------------
#dbatest1-lor-aug21: arn:aws:dms:us-east-1:273050575919:endpoint:QVSHF537BVC7XM6F6ZAIF2MJO4

$ReplicationInstanceArn = "arn:aws:dms:us-east-1:273050575919:rep:6L3UHR47FX7PJMFS5PB36CZMH66UI4RLA4KFDLY"

$EndpointParams = @{
  EndpointIdentifier = "dbatest1-lor-aug23-3"
  EndpointType = "source"
  EngineName = "sqlserver"
  Username = "dms_user"
  Password = "Desire2Learn"
  ServerName = "172.19.12.26"
  Port = "1433"
  DatabaseName = "dbatest1_lor"
  SslMode = "require"
}

$Endpoint = New-DMSEndpoint @EndpointParams

Get-DMSEndpoint -Filter @( @{name='endpoint-arn'; values= $Endpoint.EndpointArn})


$TestParams = @{
  ReplicationInstanceArn = $ReplicationInstanceArn
  EndpointArn = $Endpoint.EndpointArn
}

Test-DMSConnection @TestParams

Get-DMSConnection -Filter @( @{name='endpoint-arn'; values=$Endpoint.EndpointArn})