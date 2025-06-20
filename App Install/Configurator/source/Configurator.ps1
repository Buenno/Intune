$ErrorActionPreference = "Stop"

$appName = "Configurator"

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
  Add-StatusRegistryProperty -Application "Google Chrome" -Operating "Application Configuration" -Status "1"
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


### Start Menu & Task Bar Configurator ###
$startMenuConfig = "start2.bin"
$startMenuExpDir = "C:\Users\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
$taskbarConfig = "TaskbarLayoutModification.xml"
$taskbarDir = "$env:windir\OEM"
$taskbarRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
$taskbarRegProp = "LayoutXMLPath"
$taskbarRegValue = "$taskbarDir\$taskbarConfig"

# Create the default user start menu directory
New-Item -ItemType Directory -Path $startMenuExpDir -Force -ErrorAction SilentlyContinue | Out-Null

# Copy the start2.bin configuration file to the start menu directory
Copy-Item -Path "$PSScriptRoot\config\$startMenuConfig" -Destination "$startMenuExpDir\$startMenuConfig" -Force
Add-StatusRegistryProperty -Application $appName -Operation "Copy Start Config" -Status 0

# Create the taskbar configuration storage directory
New-Item -ItemType Directory -Path $taskbarDir -Force -ErrorAction SilentlyContinue | Out-Null

# Copy the taskbar configuration file to the storage directory
Copy-Item -Path "$PSScriptRoot\config\$taskbarConfig" -Destination "$taskbarDir\$taskbarConfig" -Force
Add-StatusRegistryProperty -Application $appName -Operation "Copy Task Config" -Status 0

# Enable use of new Taskbar configuration file in the registry
New-ItemProperty -Path $taskbarRegPath -Name $taskbarRegProp -Value $taskbarRegValue -Force | Out-Null
Add-StatusRegistryProperty -Application $appName -Operation "Task Config Registry Set" -Status 0


### Appx Uninstallers ###
$apps = @(
    "Microsoft.MicrosoftOfficeHub", 
    "Microsoft.SurfaceAppProxy", 
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.Copilot",
    "Microsoft.MicrosoftSolitaireCollection"
    )

foreach ($app in $apps){
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $app} | Remove-AppxProvisionedPackage -Online
    Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -AllUsers
    Add-StatusRegistryProperty -Application $appName -Operation "Processed $app Removal" -Status 0
}


### Remove the Edge shortcut from the public desktop ###
Remove-Item -Path "$env:PUBLIC\Desktop\Microsoft Edge.lnk" -ErrorAction SilentlyContinue
Add-StatusRegistryProperty -Application $appName -Operation "Processed Edge Shortcut Removal" -Status 0

### Change the startup type for the auto timezone updater service ###
$ATService = "tzautoupdate"
$service = Get-Service -Name $ATService -ErrorAction SilentlyContinue
if ($null -eq $service) {
    Write-Output "Service '$ATService' does not exist."
} 
else {
    $startType = (Get-Service -Name $ATService).StartType
    if ($startType -ne "Automatic") {
        Set-Service -Name $ATService -StartupType Automatic
    } 
    Add-StatusRegistryProperty -Application $appName -Operation "Processed tzautoupdate service settings" -Status 0
}