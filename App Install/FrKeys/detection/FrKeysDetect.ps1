$appName = "FrKeys"
$exe = Get-ChildItem -Path "C:\Program Files\FrKeys\FrKeys.exe" -ErrorAction SilentlyContinue
$statusReg = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appName"

# Check if status registry keys exist
$ops = @(
    "Installation"
)

$sRegCheck = Get-Item -Path $statusReg -ErrorAction SilentlyContinue | Foreach-Object {Get-ItemPropertyValue -Path $_.PSPath -Name $_.Property | Where-Object {$_ -eq "0"}} 

# Check if the correct number of operations are stored in the registry
$opsRegCheck = $ops.Count -eq $sRegCheck.Count

if (($exe) -and ($opsRegCheck)) {
    Write-Host "$appName is installed"
    exit 0
}
else {
    Write-Host "$appName is not installed"
    exit 1
}