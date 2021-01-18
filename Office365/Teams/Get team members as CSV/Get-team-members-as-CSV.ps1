
Param
(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]
    $TeamName
)

# Region module manager

function CheckModules {
    param (
        $Modules,
        $Scope
    )
    process {

        $installedModules = Get-InstalledModule

        foreach ($module in $Modules) {
            
            $GalleryModule = Find-Module -Name $module

            $mod = $installedModules | Where-Object { $_.Name -eq $module }
        
            if ([string]::IsNullOrEmpty($mod) -or [string]::IsNullOrWhiteSpace($mod)) {
                Write-Host("Modulo $($module) non trovato. Installazione in corso...")
                Install-Module -Name $module -Scope $Scope
            }
            else {
                Write-Host("Modulo $($module) trovato.")

                if ($GalleryModule.Version -ne $mod.Version) {
                    Write-Host("Aggionamento del modulo $($module) in corso...")

                    Update-Module -Name $module
                }
            }

            Import-Module -Name $module
        }

        
    }
}

function VerifyPsVersion {
    
    process {
        
        Write-Warning("Verifica dell'ambiente in corso, attendere...")

        # if ($PSVersionTable.PSVersion.Major -ne 5) {
        #     Write-Error("Questo script può essere eseguito solo con la versione 5 di Windows PowerShell")
        #     exit
        # }
    }
}

function InstallLocalModules {
    param (
        $Scope,
        $Modules
    )

    process {

        VerifyPsVersion

        CheckModules -Modules $Modules -Scope $Scope
        
    }
    
}

function ExportResults {
    param (
        $Results,
        $TeamName
    )

    process {
        $dateTime = Get-Date -Format "MMMM-dd-yyyy"

        $FileName = ".\ExportResult_" + "$($TeamName)" + "_" + "$($dateTime)" + ".csv"

        $Results | Export-Csv $FileName -UseCulture

        $currentPath = Get-Location

        Write-Warning("Esportazione utenti completata di $($FileName)")
        Write-Host("Percorso di output $($currentPath.Path)")

    }
}

# EndRegion

InstallLocalModules -Modules "MicrosoftTeams" -Scope "CurrentUser"

Connect-MicrosoftTeams

Write-Warning("Ricerca del team $($TeamName) in corso, attendere.")
Write-Host("A seconda della dimensione della tua organizzazione e del numero di team, l'operazine potrebbe richiedere alcuni minuti.")

$TeamsData = Get-Team -DisplayName $TeamName

if ($null -eq $TeamsData) {
    $TeamsData = Get-Team -MailNickName $TeamName
    
}

if ($null -eq $TeamsData) {
    Write-Warning("Errore, impossibile trovare un team con il nome $($TeamName).")
    exit        
}
else {

    Write-Host("Team trovati: $($TeamsData.Count)")

    foreach ($TeamData in $TeamsData) {
        Write-Host("")

        Write-Warning("Riepilogo dati del team:")
        Write-Host("DisplayName: " + $TeamData.DisplayName)
        Write-Host("NickName: " + $TeamData.MailNickName)
        Write-Host("Visibility: " + $TeamData.Visibility)

        Write-Host("")

        Write-Warning("Esportazione utenti in corso sul team $($TeamData.DisplayName), attendere...")
        $UsersList = Get-TeamUser -GroupId $TeamData.GroupId

        $fileName = $TeamData.DisplayName + "_" + $TeamData.MailNickName
        ExportResults -Results $UsersList -TeamName $fileName
        
    }

}

Disconnect-MicrosoftTeams

Write-Host("Esecuzione script completata.")
