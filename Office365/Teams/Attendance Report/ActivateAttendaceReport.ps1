
# Region module manager

function PrepareEnvironment {

    param(
        [Parameter(
            HelpMessage = "List of modules to be installed.",
            Mandatory = $true)]
        [string[]]
        $ModulesToInstall,

        [Parameter(
            HelpMessage = "If true, this script has dependecies in order to be executed only on PowerShell 5.x.",
            Mandatory = $false)]
        [bool]
        $OnlyPowerShell5 = $false,

        [Parameter(
            HelpMessage = "If true, this script has dependecies in order to be executed PowerShell >=6.x.",
            Mandatory = $false)]
        [bool]
        $OnlyAbovePs6 = $false,

        [Parameter(
            HelpMessage = "Scope of the module installation (CurrentUser or AllUsers). Default: CurrentUser",
            Mandatory = $false)]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]
        $Scope = "CurrentUser"
    )

    process {
        $_customMod = "ModuleManager.psm1"
        $_libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/Module%20Manager/$($_customMod)"
        $_client = New-Object System.Net.WebClient
        $_currentPath = Get-Location
        $_downloadPath = Join-Path -Path $_currentPath.Path -ChildPath $_customMod
        $_client.DownloadFile($_libraryUrl, $_downloadPath)
        $_modToImport = Join-Path -Path $_currentPath.Path -ChildPath $_customMod -Resolve
        Import-Module $_modToImport
        Get-EnvironmentInstaller -Modules $ModulesToInstall - $OnlyPowerShell5 -Scope $Scope
        Remove-Item -Path $_modToImport -Force
    }

}

function ExitSessions {

    process {
        Disconnect-MicrosoftTeams -Confirm:$false
    }
    
}

# EndRegion

PrepareEnvironment -ModulesToInstall "MicrosoftTeams"

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
