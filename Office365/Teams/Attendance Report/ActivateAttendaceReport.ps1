
$OrganizerOnly = 1
$NotOnlyOrganizer = 2

Write-Warning("Verifica dell'ambiente in corso, attendere...")

if ($PSVersionTable.PSVersion.Major -ne 5) {
    Write-Error("Questo script può essere eseguito solo con la versione 5 di Windows PowerShell")
    exit
}

$modName = "MicrosoftTeams"

$mod = Get-InstalledModule -Name $modName

if ([string]::IsNullOrEmpty($mod) -or [string]::IsNullOrWhiteSpace($mod)) {
    Write-Error("Modulo $($modName) non trovato. Installazione in corso...")
    Install-Module -Name MicrosoftTeams -RequiredVersion 1.1.6 -Scope CurrentUser
}

$mod_version = $mod.Version.ToString()
$older = 1

if ($mod_version.CompareTo("1.1.6") -eq $older) {
    Write-Error("Aggiornamento in corso del modulo $($modName), versione attualmente in uso $($mod_version) ...")
    Update-Module -Name $modName -Scope CurrentUser -Force
    
}


Import-Module -Name $modName

Write-Output("Modulo attualmente in uso:")
Write-Output($mod)
Write-Output("")
Write-Output("")

Write-Output("Inserisci il numero inerente la policy che vuoi applicare a livello di tenant:")
Write-Output("$($OrganizerOnly). download attendance report disponibile solo per chi ha programmato la riunione")
Write-Output("$($NotOnlyOrganizer). download attendance report disponibile per tutti i relatori e partecipanti nel meeting")

$response = Read-Host("Inserisci 1 o 2 e premi INVIO")

Write-Output("")
Write-Output("")

if ([string]::IsNullOrEmpty($response) -or [string]::IsNullOrWhiteSpace($response)) {
    Write-Error("Valore non corretto.")
    exit
}

Write-Warning("Inserire le credenziali dell'amministratore del tanant nella finestra che si è appena aperta")


$adminCred = Get-Credential

if($null -eq $adminCred){
    Write-Warning("Credenziali errate, riprovare")
    exit
}

$session = New-CsOnlineSession -Credential $adminCred

if($null -eq $session){
    Write-Warning("Credenziali errate, riprovare")
    exit
}

Connect-MicrosoftTeams -Credential $adminCred 
Import-PSSession $session -AllowClobber



if ($OrganizerOnly -eq $response) {

    # download report solo per chi ha programmato la riunione
    Set-CsTeamsMeetingPolicy -AllowEngagementReport "Enabled"
    $msg = "Applicazione della policy 'Solo organizzatore' completata, la propagazione della modifica potrebbe richiedere fino a 24 ore."
    Write-Warning($msg)

}
elseif ($NotOnlyOrganizer -eq $response) {
    
    # download report per tutti i relatori e partecipanti
    Set-CsTeamsMeetingPolicy -Identity Global -AllowEngagementReport "Enabled"
    $msg = "Applicazione della policy 'tutti i relatori e partecipanti' completata, la propagazione della modifica potrebbe richiedere fino a 24 ore."
    Write-Warning($msg)

}
else {
    Write-Error("Scelta corretta. Nessuna modifica apportata al sistema.")
}

Write-Output("*** Esecuzione completata ***")