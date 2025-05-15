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