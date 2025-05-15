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
$taskRunAs = "LOCALSERVICE" #"BUILTIN\Users" # S-1-5-32-54

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

<# Unregister any existing tasks with the same name
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue){
    Unregister-ScheduledTask -TaskName $taskName
}

$scheduleObject = New-Object -ComObject schedule.service
$scheduleObject.connect()
$rootFolder = $scheduleObject.GetFolder("\")
Delete Folder - $rootFolder.DeleteFolder("$taskFolder",$unll)
Create Folder - $rootFolder.CreateFolder("$taskFolder")
#>

$STaction  = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowershell\v1.0\PowerShell.exe" -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy bypass -File `"$localScriptPath\$scriptName`""
$STtrigger = New-ScheduledTaskTrigger -AtLogOn
$STSet     = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -RestartInterval (New-TimeSpan -Minutes 1) -RestartCount 3 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd
$STuser    = New-ScheduledTaskPrincipal -UserId $taskRunAs -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -TaskPath $taskFolder  -Action $STaction -Settings $STSet -Trigger $STtrigger -Principal $STuser -Force

# Enable Task Scheduler logs
<#
$logName = 'Microsoft-Windows-TaskScheduler/Operational'
$log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logName
$log.IsEnabled=$true
$log.SaveChanges()
#>
wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true

Add-StatusRegistryProperty -Application $appName -Operation $taskOp -Status '0'