
<#

Sets the user-id on Palo firewalls

#>

function Send-SyslogMessage {
    [CmdletBinding(PositionalBinding = $false,                  
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
  
    Param(
        # The message to send
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Message,
  
        # The syslog server hostname/IP
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $EndPoint,
  
        # The protocol to use
        [Parameter(Mandatory = $false)]
        [ValidateSet("UDP", "TCP")]
        [string]
        $Protocol = "TCP",
  
        # The severity of the event
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Emergency", "Alert", "Critical", "Error", "Warning", "Notice", "Information", "Debug")]
        [String]
        $Severity,
  
        # The facility of the event
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Kern", "User", "Mail", "Daemon", "Auth", "Syslog", "LPR",
            "News", "UUCP", "Cron", "AuthPriv", "FTP", "NTP", "Security",
            "Console", "Solaris-Chron", "Local0", "Local1", "Local2",
            "Local3", "Local4", "Local5", "Local6", "Local7")]
        [String]
        $Facility,
  
        # The host name of the sending
        [Parameter(Mandatory = $false)]
        [String]
        $Hostname = $env:COMPUTERNAME,
  
        # The application name
        [Parameter(Mandatory = $false)]
        [String]
        $Application = "PowerShell",
  
        # The syslog server port
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Port = 514
    )
    #endregion
  
    #region Begin
    Begin {
    }
    #endregion
  
    #region Process
    Process {
        # Process the facility
        [int]$FacilityInt = -1
        switch ($Facility) {
            'Kern' { $FacilityInt = 0 }
            'User' { $FacilityInt = 1 }
            'Mail' { $FacilityInt = 2 }
            'Daemon' { $FacilityInt = 3 } 
            'Auth' { $FacilityInt = 4 }
            'Syslog' { $FacilityInt = 5 }
            'LPR' { $FacilityInt = 6 }
            'News' { $FacilityInt = 7 }
            'UUCP' { $FacilityInt = 8 }
            'Cron' { $FacilityInt = 9 }
            'AuthPriv' { $FacilityInt = 10 }
            'FTP' { $FacilityInt = 11 }
            'NTP' { $FacilityInt = 12 }
            'Security' { $FacilityInt = 13 } 
            'Console' { $FacilityInt = 14 }
            'Solaris-Chron' { $FacilityInt = 15 }
            'Local0' { $FacilityInt = 16 }
            'Local1' { $FacilityInt = 17 }
            'Local2' { $FacilityInt = 18 }
            'Local3' { $FacilityInt = 19 }
            'Local4' { $FacilityInt = 20 }
            'Local5' { $FacilityInt = 21 }
            'Local6' { $FacilityInt = 22 }
            'Local7' { $FacilityInt = 23 } 
            Default {}
        }
  
        # Process the severity
        [int]$SeverityInt = -1
        switch ($Severity) {
            'Emergency' { $SeverityInt = 0 }
            'Alert' { $SeverityInt = 1 }
            'Critical' { $SeverityInt = 2 }
            'Error' { $SeverityInt = 3 }
            'Warning' { $SeverityInt = 4 }
            'Notice' { $SeverityInt = 5 }
            'Information' { $SeverityInt = 6 }
            'Debug' { $SeverityInt = 7 }
            Default {}
        }
  
        # Calculate the priority of the message
        $Priority = ($FacilityInt * 8) + [int]$SeverityInt
  
        # Get the timestamp in RFC 5424 format
        $Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.ffffffK")
  
        foreach ($m in $Message) {
            # Format the syslog message according to RFC 5424
            $syslogMessage = "<{0}>1 {1} {2} {3} - - - {4}`r`n" -f $Priority, $Timestamp, $Hostname, $Application, $m
            Write-Verbose ("Sending message: " + $syslogMessage)
  
            # Create an encoding object to encode to ASCII
            $Encoder = [System.Text.Encoding]::ASCII
  
            # Convert the message to byte array
            try {
                Write-Verbose "Encoding the message."
                $syslogMessageBytes = $Encoder.GetBytes($syslogMessage)
            }
            catch {
                Write-Error "Failed to encode the message to ASCII."
                continue
            }
  
            # Send the Message
            if ($Protocol -eq "UDP") {
                Write-Verbose "Sending using UDP."
  
                # Create the UDP Client object
                $UDPCLient = New-Object System.Net.Sockets.UdpClient
                $UDPCLient.Connect($EndPoint, $Port)
  
                # Send the message
                try {
                    $UDPCLient.Send($syslogMessageBytes, $syslogMessageBytes.Length) |
                    Out-Null
                    Write-Verbose "Message sent."
                }
                catch {
                    Write-Error ("Failed to send the message. " + $_.Exception.Message)
                    continue
                }
            }
            else {
                Write-Verbose "Sending using TCP."
  
                # Send the message via TCP
                
                try {
                    # Create a TCP socket object
                    $socket = New-Object System.Net.Sockets.TcpClient($EndPoint, $Port)
  
                    # Write the message in the stream
                    $stream = $socket.GetStream()
                    $stream.Write($syslogMessageBytes, 0, $syslogMessageBytes.Length)
  
                    # Flush and close the stream
                    $stream.Flush()
                    $stream.Close()
  
                    Write-Verbose "Message sent."
                }
                catch {
                    Write-Error ("Failed to send the message. " + $_.Exception.Message)
                    continue
                }
            }
        }
    }
}

# Get a list of logged in users
$queryUser = query user | ForEach-Object { ($_.trim() -replace ">" -replace "\s{2,}", ",") } | ConvertFrom-Csv 
$users = New-Object System.Collections.ArrayList
foreach ($u in $queryUser) {
    $user = [PSCustomObject]@{
        Username     = $u.USERNAME
        SessionState = $u.STATE.Replace("Disc", "Disconnected")
        SessionType  = $($u.SESSIONNAME -Replace '#', '' -Replace "[0-9]+", "")
        LogonTime    = [datetime]::parseexact($u.'LOGON TIME', 'dd/MM/yyyy HH:mm', $null)
    }
    $users.Add($user) | Out-Null
}
# Select the active user who logged in last
$username = ($users | Where-Object { $_.SessionState -eq "Active" -and $_.SessionType -eq "console" } | Sort-Object LogonTime -Descending | Select-Object -First 1).Username

# Get active network interfaces
$netInterfaces = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" }

# Loop through each active interface and notify Palo of its IP
if ($username) {
    foreach ($int in $netInterfaces) {
        $ipAddress = ($int | Get-NetIPAddress -AddressFamily IPv4).IPAddress
    
        try {
            Send-SyslogMessage -Message "username $username ip $ipAddress" -EndPoint 10.1.10.28 -Protocol UDP -Severity Information -Facility Daemon -Hostname $env:COMPUTERNAME -Application "UserID"
        }
        catch {
            Write-Error "Error contacting syslog: $_"
        }
    }
}