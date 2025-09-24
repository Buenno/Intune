$ErrorActionPreference = 'Stop'

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

$appName = "FrKeys"

# Stop process
Get-Process -Name $appName | Stop-Process -Force

# Remove app files from program files dir
Remove-Item -Path "C:\Program Files\FrKeys" -Recurse -Force

# Remove shortcut from all users start menu dir
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\FrKeys.lnk" -Recurse -Force

# Remove status registry key
Remove-StatusRegistryKey -Application $appName