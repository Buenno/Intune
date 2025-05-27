$ErrorActionPreference = 'Stop'

# Application details
$appName = "Securly SmartPAC"
$localScriptPath = "$env:SystemRoot\Scripts\$appName"

# Operations to log in the registry
$copyOp = "File Copied"
$taskOp = "Task Created"

# Script to schedule
$scriptName = "Set-SmartPAC.ps1"
$scriptPath = "$PSScriptRoot\$scriptName"

# Schedule details
$taskName = "Securly SmartPAC"
$taskFolder = "Securly"
$taskRunAs = "SYSTEM"

function Remove-StatusRegistryKey {
  <#
  .SYNOPSIS
  Removes an application status key from the registry.

  .DESCRIPTION
  Removes an application installation status key from the registry based on the supplied application name.

  .PARAMETER Application
  The name of the application as listed in the registry.
  
  .OUTPUTS
  None

  .EXAMPLE
  Remove-StatusRegistryKey -Application "Google Chrome"
  #>
  [CmdletBinding()]
  param(
      [Parameter(Mandatory = $true)]
      [string[]] $Application
  )
  BEGIN {
      $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
  }
  PROCESS {
      $statusReg = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$Application"
      if ((Test-Path $statusReg)){
          Remove-Item -Path $statusReg -Recurse -Force
      }
  }
} 

function Add-StatusRegistryProperty {
  <#
  .SYNOPSIS
  Adds an application status value to the registry.

  .DESCRIPTION
  Adds an application installation status value to the registry based on the supplied parameters, creates a parent key using the application name if required.
  
  .PARAMETER Application
  The name of the application. 

  .PARAMETER Operation
  The name of the operation your would like to add the status for.

  .PARAMETER Status
  The status of the operation. Valid values are "0" = Failed, and "1" = Success.
  
  .OUTPUTS
  None

  .EXAMPLE
  Add-StatusRegistryProperty -Application "Google Chrome" -Operation "Application Configuration" -Status "1"
  #>
  [CmdletBinding()]
  param(
      [Parameter(Mandatory = $true)]
      [string]$Application,
      [Parameter(Mandatory = $true)]
      [string]$Operation,
      [Parameter(Mandatory = $true)]
      [ValidateSet("0","1")]
      [string]$Status
  )
  BEGIN {
      $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
      $statusReg = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$Application"
      # Create status registry key if it doesn't exist
      if (!(Test-Path $statusReg)){
          New-Item -Path $statusReg -Force | Out-Null
      }
  }
  PROCESS {
      # Add status value to registry  
      New-ItemProperty -Path $statusReg -Name $Operation -Value $Status -PropertyType String -Force | Out-Null
  }
}

# Delete any existing registry status keys
Remove-StatusRegistryKey -Application $appName

# Copy script to local storage
if (!(Test-Path -Path $localScriptPath)){
    New-Item -ItemType Directory -Path $localScriptPath
}
Copy-Item -Path $scriptPath -Destination $localScriptPath -Force

Add-StatusRegistryProperty -Application $appName -Operation $copyOp -Status '0'

$STaction  = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowershell\v1.0\PowerShell.exe" -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy bypass -File `"$localScriptPath\$scriptName`""
$STtrigger = New-ScheduledTaskTrigger -AtLogOn
$STSet     = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -RestartInterval (New-TimeSpan -Minutes 1) -RestartCount 3 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd
$STuser    = New-ScheduledTaskPrincipal -UserId $taskRunAs -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -TaskPath $taskFolder  -Action $STaction -Settings $STSet -Trigger $STtrigger -Principal $STuser -Force

# Enable task scheduler logs
wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true

Add-StatusRegistryProperty -Application $appName -Operation $taskOp -Status '0'
# SIG # Begin signature block
# MIII4gYJKoZIhvcNAQcCoIII0zCCCM8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB4byFYZZR6Ml6Y
# mh60PTnUCwrK8PVv3nuXg42w91DjWaCCBi8wggYrMIIFE6ADAgECAhMhAAAA7Ept
# vi0eDYz1AAAAAADsMA0GCSqGSIb3DQEBCwUAMEAxGDAWBgoJkiaJk/IsZAEZFghp
# bnRlcm5hbDETMBEGCgmSJomT8ixkARkWA3RhczEPMA0GA1UEAxMGVEFTLUNBMB4X
# DTI1MDMwNDEwMjc0NVoXDTMwMDMwNDEwMzc0NVowfTEYMBYGCgmSJomT8ixkARkW
# CGludGVybmFsMRMwEQYKCZImiZPyLGQBGRYDdGFzMRcwFQYDVQQLEw5UaGVBYmJl
# eVNjaG9vbDEOMAwGA1UECxMFVXNlcnMxDjAMBgNVBAsTBUFkbWluMRMwEQYDVQQD
# EwpXaWxsaWFtc1RvMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0SWK
# RLSJ94ILIdqcvglMSVju2d0UC42j5nmvCOZc0Iq2ai6eWj3jsCRdBg5ZtGlnITLz
# 7OE+6DyAYVSJNeDnsF+bHvfIiiCNsRA5DUl032Gxpxirrtqxtve/gmjYWJH9HmXe
# mnIUv1iFBmIah9Xxi81F701Mi0ch6JWOsLHZxLcP2NAVmDlGz738Kc0H3K3Ku1zS
# a1BPhBgzmJU67aR0RbKpIoreCVsPhPJkE+JFGsnkCppRcHLVVfcD8QuPDYWv176M
# pWSO/JdctFKp7/PyKz6F4691XDCCxdRQ9BOyCUIYy4fcGldSNOo34MHht4HO765z
# dGC2+sNvaGLlXCCFIQIDAQABo4IC3zCCAtswPgYJKwYBBAGCNxUHBDEwLwYnKwYB
# BAGCNxUIhYn+TYafg3OB3ZEogZeWY4TAnFqBW4GG2QCC4foxAgFkAgETMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBsG
# CSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFCjds2zuvJ5sbPyk
# jxX4nVRZne9WMB8GA1UdIwQYMBaAFLxVFynKVOtreZwIEVNIDaSHF99FMIHEBgNV
# HR8EgbwwgbkwgbaggbOggbCGga1sZGFwOi8vL0NOPVRBUy1DQSxDTj1UQVMtQ0Es
# Q049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENO
# PUNvbmZpZ3VyYXRpb24sREM9dGFzLERDPWludGVybmFsP2NlcnRpZmljYXRlUmV2
# b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2lu
# dDCBuQYIKwYBBQUHAQEEgawwgakwgaYGCCsGAQUFBzAChoGZbGRhcDovLy9DTj1U
# QVMtQ0EsQ049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZp
# Y2VzLENOPUNvbmZpZ3VyYXRpb24sREM9dGFzLERDPWludGVybmFsP2NBQ2VydGlm
# aWNhdGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MDQG
# A1UdEQQtMCugKQYKKwYBBAGCNxQCA6AbDBlXaWxsaWFtc1RvQHRoZWFiYmV5LmNv
# LnVrMFAGCSsGAQQBgjcZAgRDMEGgPwYKKwYBBAGCNxkCAaAxBC9TLTEtNS0yMS0z
# MjIzMzI5MTQ3LTI2NzU3MzkyNzEtMjQ0NTg5ODYwNy0yMzczMDANBgkqhkiG9w0B
# AQsFAAOCAQEAg5lKOICORKew0qNh6GkRMhIdMCQ8gPKPQXxjNcr/mektolfwtKKQ
# fL2ST9DLARGc35s48eehnOvOEzxGLVtLQyrNV10nize/v1CZmr2nGraN2Z/jolme
# w7AfRdYNJMZj97XRit8LZtVaY45Qj9p/nDgEjhIdpCFeMlSRFT2WKrpDjxV8S/XW
# Pc0AfYt3FU95qDn7ncAjrOx+ha+j1ffS9UuePxKhNlmULhZvQueOH9pfFBKym1qe
# 9RIQuBWYeFWTkOTb7f1S8EHRU/iFdAbAY7ippCcD+vR1Dnmm7AgQvksI7Yaw7rAp
# gaJeU1Zt6bAj8TzHujkD1Gxi5JAOcfI9eDGCAgkwggIFAgEBMFcwQDEYMBYGCgmS
# JomT8ixkARkWCGludGVybmFsMRMwEQYKCZImiZPyLGQBGRYDdGFzMQ8wDQYDVQQD
# EwZUQVMtQ0ECEyEAAADsSm2+LR4NjPUAAAAAAOwwDQYJYIZIAWUDBAIBBQCggYQw
# GAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQx
# IgQgahowFCIH0YQCbY7f5Ec7K4muHh1kehqhVOMLOuWV03UwDQYJKoZIhvcNAQEB
# BQAEggEAAR5oXYT4q8bZOnFR3TSUAGwNnha8lNXk2OKFHMnC9tlSZfbans+CrXMf
# A4WdtTP7FGQjBeDWS+LkOwqWm7G7CsWF3Qsy1qrlj5TZJad8nv+er66TnJgvGfxz
# +4vMvxyoxFYsGniOeALVMBTp0jgriKY5UQRttK/XhURaHyVSxOUwni0oCBRZxM7P
# 8nk3F0bF4lGnUJm5lxDY8n5Van/y+o4hjz+Rx5Q1vXRGR4V0sR2JVNGaAJG1TjMv
# keLGvM0hGN1EZOO73jnARoDrYSP4KouQWu9+iQgHEf9I9N67ZWasiruEAuJw9Qp3
# 6DaVOrTiuVurWdReHPlAw902lW+o+A==
# SIG # End signature block
