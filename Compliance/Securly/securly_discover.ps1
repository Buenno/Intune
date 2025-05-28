# Checks if the current user has a valid Securly SmartPAC set

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

# Set the Securly FID
$fid = "securly@theabbey.co.uk"
$domainName = "theabbey.co.uk"

# Get a list of logged in users
$users = query user
$users = $users | ForEach-Object {($_.trim() -replace ">" -replace "\s{2,}", ",")} | ConvertFrom-Csv

# Expose the HKEY_USERS root hive
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS

# Set the default value for the result. This will be switched to false if any matching users are missing the SmartPAC registry settings
$smartPAC = $true

foreach ($u in $users){
  # We only want to match students (f.last25)
  $studentRegex = "^\w{1}\.[A-Z\-]+[0-9]{2}"
  # And our student test accounts (yeargroupStudent)
  $sTestRegex = "^\w{1}\d{1}Student"

  if ($u.USERNAME -match "$studentRegex|$sTestRegex"){
    $regKey = "HKU:\$(Get-SIDFromRegistry -User $u.USERNAME)\Software\Microsoft\Windows\CurrentVersion\Internet Settings" #"HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    $regName = "AutoConfigURL"
    $regValue = "https://uk-www.securly.com/smart.pac?fid=$fid&user=$($u.USERNAME)@$domainName"

    # Check if the property/value already exist within the registry
    if (!(Test-RegistryValue -Path $regKey -Property $regName -Value $regValue)){
      $smartPAC = $false
    }
  }
}

$output = @{SmartPAC = $smartPAC}
return $output | ConvertTo-Json -Compress