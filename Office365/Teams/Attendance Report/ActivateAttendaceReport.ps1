
# Region module manager

function Set-PsEvnironment {
    param(
        [Parameter(
            HelpMessage = "Modules name to install from the GitHub tool repo.",
            Mandatory = $false)]
        [ValidateSet("ModuleManager", "TerraformBackendOnAzure")]
        [string[]]
        $ModulesToInstall = "ModuleManager"
    )

    process {
        $psModuleExtension = "psm1"
    
        foreach ($module in $ModulesToInstall) {

            $libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/$($module)/$($module).$($psModuleExtension)"
            $module = "$($module).$($psModuleExtension)"

            $client = New-Object System.Net.WebClient
            $currentPath = Get-Location
            $downloadPath = Join-Path -Path $currentPath.Path -ChildPath $module
            $client.DownloadFile($libraryUrl, $downloadPath)
            
            $modToImport = Join-Path -Path $currentPath.Path -ChildPath $module -Resolve -ErrorAction Stop
            Import-Module $modToImport -Verbose
            Remove-Item -Path $modToImport -Force
        }
    }

}

function ExitSessions {

    process {
        Disconnect-MicrosoftTeams -Confirm:$false
    }
    
}

# EndRegion

Set-PsEvnironment -PsModulesToInstall  "MicrosoftTeams"

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
