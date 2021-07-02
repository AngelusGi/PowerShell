# PARAMETERS DESCRIPTION #

# $PathCSV = "<YOUR CSV PATH>" # ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
# $Delimiter = "<YOUR DELIMITER IN THE CSV FILE>" # ex. ';' # Delimitatore del file CSV

# END PARAMETERS #

param
(
    [parameter(Mandatory = $true)]
    [String]
    $PathCSV,
    
    [parameter()]
    [String]
    $Delimiter = ";"
)

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


if ([string]::IsNullOrWhiteSpace($Delimiter)) {
    throw "Il parametro Delimiter non può essere vuoto"
    exit
}elseif ([string]::IsNullOrWhiteSpace($PathCSV)) {
    throw "Il parametro PathCSV non può essere vuoto"
    exit
} 
else {
    Write-Host("Parametri:")
    Write-Host("Path CSV: $($PathCSV)")
    Write-Host("Delimitatore del file CSV: $($Delimiter)")
    Write-Host("***")
}


PrepareEnvironment -ModulesToInstall "MicrosoftTeams"

Connect-MicrosoftTeams

$team = Get-Team -DisplayName $TeamName

try {
            
    Write-Host("Verifica del CSV in corso...")
    $Teams = Import-Csv $PathCSV -Delimiter $Delimiter

    ForEach ($Team in $Teams) {
        if ( [string]::IsNullOrEmpty($Team.TeamName) -or [string]::IsNullOrWhiteSpace($Team.TeamName) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'TeamName' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }
    }

}
catch {
    Write-Error("Impossibile accedere al CSV, verificare il path e i campi")
    exit
}

try {
            
    Write-Host("Creazione dei team in corso...")

    ForEach ($Team in $Teams) {
        if ( [string]::IsNullOrEmpty($Team.TeamDisplayName) -or [string]::IsNullOrWhiteSpace($Team.TeamDisplayName) ) {
            $TeamDisplayName = $Team.TeamName
        } else {
            $TeamDisplayName = $Team.TeamDisplayName
        }

        if ( [string]::IsNullOrEmpty($Team.Visibility) -or [string]::IsNullOrWhiteSpace($Team.Visibility) ) {
            $Visibility = "Public"
            Write-Error("Il team $($Team.TeamName), verrà creato con visibilità $($Visibility) in quanto non è stato specificato nel file CSV")
        } else {
            $Visibility = $Team.Visibility
        }

        if ( [string]::IsNullOrEmpty($Team.Description) -or [string]::IsNullOrWhiteSpace($Team.Description) ) {
            $Description = $Team.TeamName
        } else {
            $Description = $Team.Description
        }


        New-Team -MailNickname $Team.TeamName -DisplayName $TeamDisplayName -Visibility $Visibility -Description $Description
        Write-Warning("*** Operazione compeltata su $($Team.TeamName) ***")
    }

}
catch {
    Write-Error("Impossibile creare i team.")
    exit
}

Write-Host("*** Operazione compeltata potrebbero essere necessari alcuni minuti affinché le modifiche diventino visibili ***")
