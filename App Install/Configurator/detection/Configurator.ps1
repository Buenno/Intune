$appName =      "Configurator"
$statusReg =    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appName"

# Operations which should be logged in the registry
$ops = @(
    "Copy Start Config",
    "Copy Task Config",
    "Task Config Registry Set",
    "Processed App Removal",
    "Processed App Removal",
    "Processed App Removal",
    "Processed App Removal",
    "Processed App Removal",
    "Processed Edge Shortcut Removal"
)

# Check if status registry entries exists (created by installer)
$sRegCheck = Get-Item -Path $statusReg -ErrorAction SilentlyContinue | Foreach-Object {Get-ItemPropertyValue -Path $_.PSPath -Name $_.Property | Where-Object {$_ -eq "0"}} 

# Check if the correct number of operations are stored in the registry
$opsRegCheck = $ops.Count -eq $sRegCheck.Count

# Return exit code based on checks
if ($opsRegCheck){
    Write-Host "$appName is installed"
    exit 0
}
else {
    Write-Host "$appName is not installed"
    exit 1
}