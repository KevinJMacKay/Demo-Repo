<#
    .DESCRIPTION
    Powershell script to add permissions to X509 certificate private key for specific user.
    .OUTPUTS
    Set-Acl result
    .EXAMPLE
    PS> .\Set-AclForCertificate.ps1 'CertFriendlyName' 'domain\username' 'Read'
    or
    PS> .\Set-AclForCertificate.ps1 'CertFriendlyName' 'domain\username' 'FullControl'
    
    String equivalent of System.Security.AccessControl.FileSystemRights for $permission.
    Script should be run as Administrator.
#>



param(
  [Parameter(Mandatory=$true)][string] $CertFriendlyName,
  [Parameter(Mandatory=$true)][string] $User,
  [Parameter(Mandatory=$true)][string] $Permission
)

$CertThumbprint = (Get-ChildItem 'Cert:\LocalMachine\My' | Where-Object {$_.FriendlyName -eq $CertFriendlyName}).Thumbprint
$CertObj = Get-ChildItem "Cert:\LocalMachine\My\$CertThumbprint" 
$RsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($CertObj)
$UniqueName = $RsaCert.Key.UniqueName
$KeyFilePath = "$env:ALLUSERSPROFILE\Microsoft\Crypto\RSA\MachineKeys\$UniqueName"
$Acl = Get-Acl -Path $KeyFilePath
$Rule = New-Object Security.AccessControl.FileSystemAccessRule $User, $Permission, Allow
$Acl.AddAccessRule($Rule)
Set-Acl -Path $KeyFilePath -AclObject $Acl
Write-Host "Get-Acl -Path $KeyFilePath"