# Required module to install -> https://www.microsoft.com/download/details.aspx?id=39366


$OrganizerOnly = 1
$NotOnlyOrganizer = 2

Write-Output("Inserisci il numero inerente la policy che vuoi applicare:")
Write-Output("1. download report disponibile solo per chi ha programmato la riunione")
Write-Output("2. download report disponibile solo per tutti i relatori e partecipanti")

$response = Read-Host("Inserisci 1 o 2 e premi INVIO")

if ([string]::IsNullOrEmpty($response) -or [string]::IsNullOrWhiteSpace($response)){
    Write-Error("Valore non corretto.")
    exit
}

$mod = Get-InstalledModule -Name "SkypeOnlineConnector"

if ([string]::IsNullOrEmpty($mod) -or [string]::IsNullOrWhiteSpace($mod)){
    Write-Error("Modulo non trovato. Installare il modulo da https://www.microsoft.com/download/details.aspx?id=39366 riavviare il computer e ripetere l'operazione.")
    exit
}


Import-Module SkypeOnlineConnector

$adminCred = Get-Credential
$session = New-CsOnlineSession -Credential $adminCred
Import-PSSession $session

if ($OrganizerOnly -eq $response) {

    # download report solo per chi ha programmato la riunione
    Set-CsTeamsMeetingPolicy -AllowEngagementReport Enabled

} elseif ($NotOnlyOrganizer -eq $response) {
    
    # download report per tutti i relatori e partecipanti
    Set-CsTeamsMeetingPolicy -Identity Global AllowEngagementReport Enabled

} else {
    Write-Error("Valore non corretto. Nessuna modifica apportata al sistema.")
}
