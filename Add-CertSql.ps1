param(
  [Parameter(Mandatory=$true)][string] $SqlInstanceName
)

$CertParamStoreJson = ( Get-SSMParameter -Name dba_ssl_cert -WithDecryption $true ).Value
$CertParamStore = convertfrom-json $CertParamStoreJson
$CertFriendlyName = $CertParamStore.CertFriendlyName 
$CertStorePath = Get-ChildItem -Path 'Cert:\LocalMachine\My'
$CertThumbprint = ( $CertStorePath | Where-Object { $_.FriendlyName -eq $CertFriendlyName }).Thumbprint
$RegKey = Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server" -Recurse

$RegPath = ( $RegKey  | Where-Object {  `
    $_.Name -like "*$($SqlInstanceName)*" `
     -AND $_.Name -like '*SuperSocketNetLib' `
     -AND $_.Property -like 'Certificate' `
})

Set-ItemProperty -Path $RegPath.PSPath -Name Certificate -Value $CertThumbprint.ToString().ToLowerInvariant()
# restart SQLServer