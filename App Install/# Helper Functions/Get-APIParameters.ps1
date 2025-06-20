function Get-APIParameters {
  <#
  .SYNOPSIS
  Generates Palo API Parameters 
  #>
  [CmdletBinding()]
  param(
      [Parameter(Mandatory = $true)]
      [string]$IP,
      [Parameter(Mandatory = $true)]
      [string]$APIKey,
      [Parameter(Mandatory = $true)]
      [string]$Payload
  )
  BEGIN {
      $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
  }
  PROCESS {
        $APIParameters = @{
            Uri             = "https://$IP/api/?type=user-id&key=$APIKey&cmd=$Payload"
            Method          = "Get"
            Headers         = @{
                "Content-Type" = "application/x-www-form-urlencoded"
            }
            SkipCertificateCheck  = $true
            UseBasicParsing       = $true
        }
        return $APIParameters
    }
}