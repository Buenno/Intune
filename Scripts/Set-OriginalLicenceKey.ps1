<# 
  Some devices will fail to activate if they were previously using some form of KMS or VLK.
  We can fix this by finding the original licence that the device shipped with,
  and using this to activate Windows.
#>

$GVLK = (Get-WmiObject SoftwareLicensingProduct -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f' and LicenseStatus = '5'").ProductKeyChannel

if ($GVLK -eq 'Volume:GVLK'){
  $GetDigitalLicence = (Get-WmiObject -query 'select * from SoftwareLicensingService’).OA3xOriginalProductKey
  cscript c:\windows\system32\slmgr.vbs -ipk $GetDigitalLicence
}