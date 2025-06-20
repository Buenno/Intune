$ErrorActionPreference = 'Stop'

# Application details
$appName = "Palo User-ID"
$localScriptPath = "$env:SystemRoot\Scripts\$appName"

# Operations to log in the registry
$copyOp = "File Copied"
$taskOp = "Task Created"

# Script to schedule
$scriptName = "Set-UserID.ps1"
$scriptPath = "$PSScriptRoot\$scriptName"

# Schedule details
$taskName = "Palo User-ID"
$taskFolder = "Palo"
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
        if ((Test-Path $statusReg)) {
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
        [ValidateSet("0", "1")]
        [string]$Status
    )
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        $statusReg = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$Application"
        # Create status registry key if it doesn't exist
        if (!(Test-Path $statusReg)) {
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
if (!(Test-Path -Path $localScriptPath)) {
    New-Item -ItemType Directory -Path $localScriptPath
}
Copy-Item -Path $scriptPath -Destination $localScriptPath -Force

Add-StatusRegistryProperty -Application $appName -Operation $copyOp -Status '0'

<#
    We set 3 triggers
        1: Run at logon
        2: Run every 2 hours
        3: Run at each network interface connection event or Wi-Fi disconnect
#>

$STTrigger1 = New-ScheduledTaskTrigger -AtLogOn

$STTrigger2 = New-ScheduledTaskTrigger -Daily -At 08:00 
$STTrigger2Rep = New-ScheduledTaskTrigger -Once -At 08:00 -RepetitionInterval (New-TimeSpan -Hours 2)
$STTrigger2.Repetition = $STTrigger2Rep.Repetition

$STTrigger3Class = Get-cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
$STTrigger3 = $STTrigger3Class | New-CimInstance -ClientOnly
$STTrigger3.Enabled = $true
$STTrigger3.Subscription = $STTrigger3.Subscription = '<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[(EventID=10000)]] and (*[EventData[Data[@Name="Name"] and (Data="TheAbbeySchool")]] or *[EventData[Data[@Name="Name"] and (Data="tas.internal")]])</Select></Query><Query Id="1" Path="Microsoft-Windows-WLAN-AutoConfig/Operational"><Select Path="Microsoft-Windows-WLAN-AutoConfig/Operational">*[System[(EventID=8003)]] and (*[EventData[Data[@Name="SSID"] and (Data="TheAbbeySchool")]])</Select></Query></QueryList>'

$STtrigger = @(
    $STTrigger1,
    $STTrigger2,
    $STTrigger3
)
$STaction = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowershell\v1.0\PowerShell.exe" -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy bypass -File `"$localScriptPath\$scriptName`""
$STSet = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -RestartInterval (New-TimeSpan -Minutes 1) -RestartCount 3 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -StartWhenAvailable
$STuser = New-ScheduledTaskPrincipal -UserId $taskRunAs -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -TaskPath $taskFolder  -Action $STaction -Settings $STSet -Trigger $STtrigger -Principal $STuser -Force

# Enable task scheduler logs
wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true

Add-StatusRegistryProperty -Application $appName -Operation $taskOp -Status '0'