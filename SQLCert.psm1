function Import-Certificate {

    param(
        [Parameter(Mandatory = $true)][string] $Localfolder
    )

    $CertParamStore = ( Get-SSMParameter -Name dba_ssl_cert -WithDecryption $true ).Value
    $CertParamStore = ConvertFrom-Json $CertParamStore
    $CertS3Bucket = $CertParamStore.CertS3Bucket
    $CertS3Key = $CertParamStore.CertS3Key
    $CertName = $CertParamStore.CertName
    $CertPassword = $CertParamStore.CertPassword
    $Key = "$CertS3Key/$CertName"

    Copy-S3Object -BucketName $CertS3Bucket -Key $Key -LocalFolder $Localfolder

    $CertFilePath = "$Localfolder\$CertS3Key\$CertName"
    $CertStoreLocation = 'Cert:\LocalMachine\My'
    $CertPasswordSecure = ConvertTo-SecureString -String $CertPassword -AsPlainText -Force

    $Params = @{
        FilePath          = $CertFilePath
        CertStoreLocation = $CertStoreLocation
        Password          = $CertPasswordSecure
    }

    Import-PfxCertificate @Params
}

function Set-AclCertificate {

    param(
        [Parameter(Mandatory = $true)][string] $CertFriendlyName,
        [Parameter(Mandatory = $true)][string] $User,
        [Parameter(Mandatory = $true)][string] $Permission
    )

    $CertStoreLocation = 'Cert:\LocalMachine\My'
    $CertThumbprint = ($CertStoreLocation | Where-Object { $_.FriendlyName -eq $CertFriendlyName }).Thumbprint
    $CertObj = Get-ChildItem "Cert:\LocalMachine\My\$CertThumbprint"
    $Rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($CertObj)
    $UniqueName = $Rsa.Key.UniqueName
    $KeyFilePath = "$env:ALLUSERSPROFILE\Microsoft\Crypto\RSA\MachineKeys\$UniqueName"

    $Acl = Get-Acl -Path $KeyFilePath
    $Rule = New-Object Security.AccessControl.FileSystemAccessRule $User, $Permission, Allow
    $Acl.AddAccessRule($Rule)

    Set-Acl -Path $KeyFilePath -AclObject $Acl

}


function Import-Certificate {

    param(
        [Parameter(Mandatory = $true)][string] $SqlInstanceName
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
}