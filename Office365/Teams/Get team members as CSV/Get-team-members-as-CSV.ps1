
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

PrepareEnvironment -ModulesToInstall "MicrosoftTeams"

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
