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
        [Parameter(Mandatory = $true)]
        [String[]]
        $Modules,
        [int16]
        $Version
    )
    
    process {

        $LibraryURL = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/ModuleManager.ps1"

        $Client = New-Object System.Net.WebClient
    
        $currentPath = Get-Location

        $downloadPath = $currentPath.Path + "\ModuleManager.ps1"
        
        $Client.DownloadFile($LibraryURL, $downloadPath)

        .\ModuleManager.ps1 -Modules $Modules -CompatibleVersion $Version 

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


PrepareEnvironment -Modules "MicrosoftTeams"

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
