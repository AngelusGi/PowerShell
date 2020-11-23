# Required module to install -> https://www.microsoft.com/download/details.aspx?id=39366

Write-Warning("Verifica dell'ambiente in corso, attendere...")

if ($PSVersionTable.PSVersion.Major -ne 5) {
    Write-Error("Questo script può essere eseguito solo con la versione 5 di Windows PowerShell")
    exit
}

$mod = Get-InstalledModule -Name "SkypeOnlineConnector"

if ([string]::IsNullOrEmpty($mod) -or [string]::IsNullOrWhiteSpace($mod)){
    Write-Error("Modulo non trovato. Installare il modulo da https://www.microsoft.com/download/details.aspx?id=39366 riavviare il computer e ripetere l'operazione.")
    exit
}

$OrganizerOnly = 1
$NotOnlyOrganizer = 2

Write-Output("Inserisci il numero inerente la policy che vuoi applicare a livello di tenant:")
Write-Output("$($OrganizerOnly). download attendance report disponibile solo per chi ha programmato la riunione")
Write-Output("$($NotOnlyOrganizer). download attendance report disponibile per tutti i relatori e partecipanti nel meeting")

$response = Read-Host("Inserisci 1 o 2 e premi INVIO")

if ([string]::IsNullOrEmpty($response) -or [string]::IsNullOrWhiteSpace($response)){
    Write-Error("Valore non corretto.")
    exit
}

Import-Module SkypeOnlineConnector

$adminCred = Get-Credential
$session = New-CsOnlineSession -Credential $adminCred
Import-PSSession $session

msg = "Applicazione della policy completata, la propagazione della modifica potrebbe richiedere fino a 24 ore."

if ($OrganizerOnly -eq $response) {

    # download report solo per chi ha programmato la riunione
    Set-CsTeamsMeetingPolicy -AllowEngagementReport Enabled
    Write-Warning(msg)

} elseif ($NotOnlyOrganizer -eq $response) {
    
    # download report per tutti i relatori e partecipanti
    Set-CsTeamsMeetingPolicy -Identity Global AllowEngagementReport Enabled
    Write-Warning(msg)

} else {
    Write-Error("Scelta corretta. Nessuna modifica apportata al sistema.")
}
