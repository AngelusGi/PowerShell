
# Region module manager

function CheckModules {
    param (
        $Modules,
        [String]$Scope
    )
    process {

        foreach ($module in $Modules) {
            
            $GalleryModule = Find-Module -Name $module

            $mod = $installedModules | Where-Object { $_.Name -eq $module }
        
            if ([string]::IsNullOrEmpty($mod) -or [string]::IsNullOrWhiteSpace($mod)) {
                Write-Warning("Modulo $($module) non trovato. Installazione in corso...")
                Install-Module -Name $module -Scope $Scope
            }
            else {
                Write-Warning("Modulo $($module) trovato.")

                if ($GalleryModule.Version -ne $mod.Version) {
                    Write-Warning("Aggionamento del modulo $($module) in corso...")

                    Update-Module -Name $module -Force
                }
            }
            Import-Module -Name $module

        }

        
    }
}

function VerifyPsVersion {
    
    process {
        
        Write-Warning("Verifica dell'ambiente in corso, attendere...")

        if ($PSVersionTable.PSVersion.Major -ne 5) {
            Write-Error("Questo script può essere eseguito solo con la versione 5 di Windows PowerShell")
            exit
        }
    }
}

function InstallLocalModules {
    param (
        [String]$Scope,
        $Modules
    )

    process {

        VerifyPsVersion

        CheckModules -Modules $Modules -Scope $Scope
        
    }
    
}

function ExitSessions {

    process {
        Disconnect-MicrosoftTeams -Confirm:$false
    }
    
}

# EndRegion

InstallLocalModules -Modules "MicrosoftTeams" -Scope "CurrentUser"

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
