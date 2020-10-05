# PARAMETERS DESCRIPTION #

# $TeamName = "Test Teams CSV 1" # Inserire il nome del team (lo stesso prensente anche nel CSV

# $PathCSV = ".\csv_test.CSV" #Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire

# END PARAMETERS #


Param
(
    [parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String]
    $PathCSV,

    [parameter(ValueFromPipeline=$true)]
    [String]
    $TeamName,
    
    [parameter(ValueFromPipeline=$true)]
    [String]
    $Delimiter
)

if([string]::IsNullOrEmpty($Delimiter) -or [string]::IsNullOrWhiteSpace($Delimiter)){
    $Delimiter = ";"
}


if ([string]::IsNullOrWhiteSpace($Delimiter)) {
    Write-Error("Il parametro Delimiter non può essere vuoto")
    exit
} elseif ([string]::IsNullOrWhiteSpace($TeamName)) {
    Write-Error("Il parametro TeamName non può essere vuoto")
    exit
}elseif ([string]::IsNullOrWhiteSpace($PathCSV)) {
    Write-Error("Il parametro PathCSV non può essere vuoto")
    exit
}else {
    Write-host("Parametri:")
    Write-host("Path CSV: $($PathCSV)")
    Write-host("Delimitatore del file CSV: $($Delimiter)")
    Write-host("Nome del primo team: $($TeamName)")
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

Connect-MicrosoftTeams

$team = Get-Team -DisplayName $TeamName

try {
    if ( [string]::IsNullOrWhiteSpace($team) -or [string]::IsNullOrWhiteSpace($team) ) {
        Write-Warning("*** IL TEAM NON ESISTE ***")

    } else {
        Write-Warning("*** IL TEAM ESISTE, CARICAMENTO UTENTI IN CORSO... ***")
    
        $guestUsers = Import-Csv $PathCSV -Delimiter ';'

        $guestUsers | ForEach-Object {

            $email = $_.Email

            if ($_.Team.Equals($team.DisplayName)) {
                # $group = Get-Team -MailNickName $TeamName
                
                Add-TeamUser -GroupId $team.GroupId -User $email
                Write-Warning("*** Operazione compeltata su '" + $email + "' nel team '" + $team.DisplayName + "' ***")
            
            } else {
                Write-Error("Errore, nessun team riconosciuto. Il nome team del CSV non è un nome valido.")
            }

            Write-Host("")
            Write-Host("")
        }
    }
}
catch {
    Write-Error("*** ERRORE ***")
    break
}
