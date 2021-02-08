
# Region module manager
function PrepareEnvironment {

    param(
        [Parameter(Mandatory = $true)]
        [String[]]
        $Modules,
        [int16]
        $Version
    )
    
    process {

        $LibraryURL = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/ModuleManager.ps1"

        $Client = New-Object System.Net.WebClient
    
        $Client.DownloadFile($LibraryURL, "ModuleManager.ps1")

        .\ModuleManager.ps1 -Modules $Modules -CompatibleVersion $Version 

    }
    
}

function ExitSessions {

    process {
        Disconnect-MicrosoftTeams -Confirm:$false
    }
    
}

# EndRegion

PrepareEnvironment -Modules "MicrosoftTeams"

Write-Warning("Inserire le credenziali dell'amministratore del tanant")

try {
    $adminCred = Get-Credential
    $session = New-CsOnlineSession -Credential $adminCred
    Connect-MicrosoftTeams -Credential $adminCred
    Import-PSSession $session -AllowClobber
}
catch {
    Write-Warning("Autenticazione non riuscita, verificare le credenziali inserite.")
    exit
}

$OrganizerOnly = 1
$NotOnlyOrganizer = 2

do {
    Clear-Host

    Write-Host("Inserisci il numero inerente la policy che vuoi applicare a livello di tenant:")
    Write-Host("$($OrganizerOnly). download attendance report disponibile solo per chi ha programmato la riunione")
    Write-Host("$($NotOnlyOrganizer). download attendance report disponibile per tutti i relatori e partecipanti nel meeting")
    
    $response = Read-Host("Inserisci 1 o 2 e premi INVIO")
    Write-Host("")
} while (-not (($OrganizerOnly -eq $response) -or ($NotOnlyOrganizer -eq $response)))

$msg = $null

if ($OrganizerOnly -eq $response) {

    # download report solo per chi ha programmato la riunione
    Set-CsTeamsMeetingPolicy -AllowEngagementReport "Enabled"
    $msg = "Applicazione della policy 'Solo organizzatore' completata, la propagazione della modifica potrebbe richiedere fino a 24 ore."

}
elseif ($NotOnlyOrganizer -eq $response) {
    
    # download report per tutti i relatori e partecipanti
    Set-CsTeamsMeetingPolicy -Identity Global -AllowEngagementReport "Enabled"
    $msg = "Applicazione della policy 'tutti i relatori e partecipanti' completata, la propagazione della modifica potrebbe richiedere fino a 24 ore."

}

Write-Warning($msg)

ExitSessions

Write-Host("*** Esecuzione completata ***")
