
Param
(
    [parameter(Mandatory = $true)]
    [String]
    $TeamName
)

# Region module manager

function ExitSessions {

    process {
        Disconnect-MicrosoftTeams -Confirm:$false
    }
    
}


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

Set-PsEvnironment -PsModulesToInstall  "MicrosoftTeams"

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

ExitSessions

Write-Host("Esecuzione script completata.")
