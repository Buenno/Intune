<#
  Sets the Securly SecurePAC URL for students whose username matches the defined regex. 

  This runs in the SYSTEM context, checks for all logged in users, and then loads their respective user hives and adds the required property/value.
#> 

$ErrorActionPreference = 'Stop'

function Get-SIDFromRegistry {
    <#
    .SYNOPSIS
    Gets a users SID from the registry.
  
    .DESCRIPTION
    Gets a users SID from the registry. Useful when the usual methods aren't suitable or just don't work.
    .PARAMETER User
    The username of the user. 
  
    .EXAMPLE
    Get-SIDFromRegistry -User "MyUserName"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$User
    )
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    }
    PROCESS {
        # Get profile data
        $profiles = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" | Where-Object {$_.PSChildName -match $sidRegex}
        return ($profiles | Where-Object {$_.profileimagepath -like "*$User*"}).PSChildName 
    }
  }

function Test-RegistryValue {
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Path,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Property,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Value
    )
    try {
        $prop = Get-ItemProperty -Path $Path -Name $Property -ErrorAction Stop
        if ($prop.$Property -eq $Value){
            return $true
        }
        else {
            return $false
        }
    } catch {
        return $false
    }
}

function Write-Log {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    $logPath = "$PSScriptRoot\SmartPAC.log"
    $timestamp =  Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Add-Content -Path $LogPath -Value $logEntry -Force
}

# Get a list of logged in users
$users = query user
$users = $users | ForEach-Object {($_.trim() -replace ">" -replace "\s{2,}", ",")} | ConvertFrom-Csv
# Expose the HKEY_USERS root hive
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS

foreach ($u in $users){
    # We only want to match students (f.last25)
    $studentRegex = "^\w{1}\.[A-Z\-]+[0-9]{2}"
    # And our student test accounts (yeargroupStudent)
    $sTestRegex = "^\w{1}\d{1}Student"
    

    if ($u.USERNAME -match "$studentRegex|$sTestRegex"){
        # Create a custom object for storing our user data, because we think ahead..
        $user = [PSCustomObject]@{
            Username = $u.USERNAME
            SID = (Get-SIDFromRegistry -User $u.USERNAME)
            SessionState = $u.STATE.Replace("Disc", "Disconnected")
            SessionType = $($u.SESSIONNAME -Replace '#', '' -Replace "[0-9]+", "")
            LogonTime = [datetime]::parseexact($u.'LOGON TIME', 'dd/MM/yyyy HH:mm', $null)
        } 

        $regKey = "HKU:\$($user.SID)\Software\Microsoft\Windows\CurrentVersion\Internet Settings" #"HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        $regName = "AutoConfigURL"
        $regValue = "https://uk-www.securly.com/smart.pac?fid=SECURLYFID&user=$($user.Username)@DOMAINNAME.co.uk"

        # Check if the property/value already exist within the registry
        if (!(Test-RegistryValue -Path $regKey -Property $regName -Value $regValue)){
            # Add registry key
            New-ItemProperty -Path $regKey -Name $regName -Value $regValue -PropertyType String -Force | Out-Null
            Write-Log -Message "Added $regName for user $($user.Username). The value of $regValue was added to the key $regKey."
        }
    }
}