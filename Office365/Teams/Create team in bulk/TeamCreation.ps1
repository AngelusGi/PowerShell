# PARAMETERS DESCRIPTION #

# $PathCSV = "<YOUR CSV PATH>" # ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
# $Delimiter = "<YOUR DELIMITER IN THE CSV FILE>" # ex. ';' # Delimitatore del file CSV

# END PARAMETERS #

param
(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]
    $PathCSV,
    
    [parameter(ValueFromPipeline = $true)]
    [String]
    $Delimiter
)

if ([string]::IsNullOrEmpty($Delimiter) -or [string]::IsNullOrWhiteSpace($Delimiter)) {
    $Delimiter = ";"
}


if ([string]::IsNullOrWhiteSpace($Delimiter)) {
    Write-Error("Il parametro Delimiter non può essere vuoto")
    exit
}
elseif ([string]::IsNullOrWhiteSpace($PathCSV)) {
    Write-Error("Il parametro PathCSV non può essere vuoto")
    exit
}
else {
    Write-host("Parametri:")
    Write-host("Path CSV: $($PathCSV)")
    Write-host("Delimitatore del file CSV: $($Delimiter)")
    Write-Host("***")
}

Write-Output("Preparazione e verifica dell'ambiente in corso, attendere...")

try {
    $PSTeamsModule = "MicrosoftTeams"

    $ModTeams = Get-InstalledModule -Name $PSTeamsModule

    if ($null -eq $ModTeams) {
        Install-Module -Name $PSTeamsModule -Force
    }
}
catch {
    Write-Error("Modulo $($PSTeamsModule) non trovato...")
    exit
}

Import-Module -Name $PSTeamsModule

Connect-MicrosoftTeams

$team = Get-Team -DisplayName $TeamName

try {
            
    Write-Output("Verifica del CSV in corso...")
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
            
    Write-Output("Creazione dei team in corso...")

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

Write-Output("*** Operazione compeltata potrebbero essere necessari alcuni minuti affinché le modifiche diventino visibili ***")
