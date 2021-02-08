[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $InputCsv,
    [Parameter()]
    [string]
    $OutputCsv = ".\Output-MX.csv",
    [Parameter()]
    [string]
    $Delimiter = ',',
    [Parameter()]
    [string]
    $Encoding = "utf8",
    [Parameter()]
    [string]
    $SearchType = "MX"
)

$DomainsCsv = Import-Csv -Path $InputCsv -Delimiter $Delimiter -Encoding $Encoding

foreach ($item in $DomainsCsv) {
    Write-Host("Ricerca di $($item) in corso...")
    Resolve-DnsName -Name $item.Domain -Type $SearchType | Export-Csv $OutputCsv -Append -Force

}

Write-Warning("*** Esecuzione completata ***")
