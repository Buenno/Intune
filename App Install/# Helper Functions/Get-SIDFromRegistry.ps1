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