$Localfolder = "C:\DBA_Scripts"

$CertParamStore = ( Get-SSMParameter -Name dba_ssl_cert -WithDecryption $true ).Value
$CertParamStore = convertfrom-json $CertParamStore
$CertS3Bucket = $CertParamStore.CertS3Bucket
$CertS3Key = $CertParamStore.CertS3Key
$CertName = $CertParamStore.CertName
$CertPassword = $CertParamStore.CertPassword

$Key = "$CertS3Key/$CertName" 
Copy-S3Object -BucketName $CertS3Bucket -Key $Key -LocalFolder $Localfolder

$CertFilePath = "$Localfolder\$CertS3Key\$CertName"
$CertStoreLocation = 'Cert:\LocalMachine\My'

$CertPasswordSecure = ConvertTo-SecureString -String $CertPassword -AsPlainText -Force

$params = @{ 
	FilePath = $CertFilePath 
	CertStoreLocation = $CertStoreLocation
	Password = $CertPasswordSecure
} 
Import-PfxCertificate @params