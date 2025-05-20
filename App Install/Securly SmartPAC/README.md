# Securly SmartPAC   

### About
This app configures the Securly SmartPAC client settings in order to proxy traffic through Securly's servers.

* Creates a scheduled task which runs as SYSTEM every time someone logs into the device 
* Scheduled tasks executes a Powershell script which:
    * Identifies the users currently logged into the device and which of those are student accounts
    * Loops through the student accounts, loads their registry hives if required, and sets the SmartPAC key/value
* Logs to C:\Windows\Scripts\

### Signing Scripts

Please note that the installation script utilises code which will not run in Constrained Language Mode, therefore the script will need to be signed if using App Control with script enforcement. 

Once you've install your code signing cert, store it in a variable with `$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert`.

You can then sign your scripts with `Set-AuthenticodeSignature -Certificate $cert -FilePath .\Set-Wallpaper.ps1`.

You can then proceed with building your .intunewin package as normal.
 