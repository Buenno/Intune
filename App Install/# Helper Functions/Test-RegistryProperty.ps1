function Test-RegistryProperty {
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Path,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Property
    )
    try {
        Get-ItemProperty -Path $Path -Name $Property -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}