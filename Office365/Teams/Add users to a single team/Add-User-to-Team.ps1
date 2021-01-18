# We are using the preview module of Teams for PowerShell in order to use this method Add-TeamChannelUser - Ref. https://docs.microsoft.com/en-us/powershell/module/teams/Add-TeamChannelUser?view=teams-ps
# Install Teams PowerShell public preview - Ref. https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-install#install-teams-powershell-public-preview

# Expeting those mandatory headers in the CSV file: "Email" (case sensitive)
# All the members are added to only to private channels

# PARAMETERS #

# MANDATORY #
    # $PathCSV = "<YOUR CSV PATH>" # ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
    # $TeamName = "<TEAM NAME>" # ex. "Team Contoso"

# OTPIONAL PARAMETERS #
    # $Delimiter = "<YOUR DELIMITER IN THE CSV FILE>" # ex. ';' # Delimitatore del file CSV
    # $Role = "Member" # the deafult member type is "Member", istead of this you can set this parameter as "Owner"

# END PARAMETERS #


Param
(
    [parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String]
    $PathCSV,

    [parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String]
    $TeamName,

    [parameter(ValueFromPipeline=$true)]
    [String]
    $Delimiter,

    [parameter(ValueFromPipeline=$true)]
    [String]
    $Role
)

if([string]::IsNullOrEmpty($Delimiter) -or [string]::IsNullOrWhiteSpace($Delimiter)){
    $Delimiter = ";"
}

if([string]::IsNullOrEmpty($Role) -or [string]::IsNullOrWhiteSpace($Role)){
    $Role = "Member"
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
}elseif ([string]::IsNullOrWhiteSpace($Role)) {
    Write-Error("Il parametro Role non può essere vuoto")
    exit    
}else {
    Write-host("Riepilogo parametri:")
    Write-host("Path CSV: $($PathCSV)")
    Write-host("Delimitatore del file CSV: $($Delimiter)")
    Write-host("Nome del team: $($TeamName)")
    Write-host("Ruolo nel team: $($Role)")
    Write-host("***")

}


Write-Host("Preparazione e verifica dell'ambiente in corso, attendere...")

try {
    $PSTeamsModule = "MicrosoftTeams"

    $ModTeams = Get-InstalledModule -Name $PSTeamsModule

    if ($null -eq $ModTeams) {
        Install-Module -Name $PSTeamsModule -Scope CurrentUser -Force
    }
    
}
catch {
    Write-Error("Modulo $($PSTeamsModule) non trovato...")
    break
}

Import-Module -Name $PSTeamsModule

Write-Host("Riepilogo moduli trovati")
Get-InstalledModule -Name $PSTeamsModule

Connect-MicrosoftTeams


try {


    $FoundUsers = New-Object -TypeName "System.Collections.ArrayList"
    $ErrorUser = $null

    $TempFileName = $PathCSV.Replace(".\", "")
    $FileName = $TempFileName.Replace(".CSV", "")
    $OutputName = "$($FileName).txt"

    Write-Host("Ricerca del Team $($TeamName) in corso, attendere...")
    $Team = Get-Team -DisplayName $TeamName

    if ($null -eq $Team) {
        Write-Error("Il team indicato non esiste $($TeamName), creazione in corso...")
        
    }

    try {
        
        try {
            
            Write-Host("Verifica del CSV in corso...")
            $Users = Import-Csv $PathCSV -Delimiter $Delimiter

            ForEach ($User in $Users) {
                if ( [string]::IsNullOrEmpty($User.Email) -or [string]::IsNullOrWhiteSpace($User.Email) ) {
                    Write-Error("Il CSV non è formattato correttamente, verificare il campo 'Email' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
                    exit
                }
            }

        }
        catch {
            Write-Error("Impossibile accedere al CSV, verificare il path e i campi")
            exit
        }
        

        Write-Host("Ricerca dei membri gia presenti nel team $($Team.DisplayName) in corso...")
        $TeamUsers = Get-TeamUser -GroupId $Team.GroupId -Role $Role

        foreach ($User in $Users) {

            try {

                if ( ($null -eq $TeamUsers) -or (-not $TeamUsers.User.Contains($User.Email))) {
                    try {
                        $ErrorUser = $User
                        Write-Host("Aggiunta dell'utente $($User.Email) al team $($Team.DisplayName) in corso, attendere...")
                        Add-TeamUser -GroupId $Team.GroupId -User $User.Email
                        Start-Sleep -Seconds 15
                        Write-Host("$($User.Email) aggiunto al team $($Team.DisplayName)")
                    }
                    catch {
                        Write-Error("L'utente $($User.Email) non presente in Microsoft Teams!")
                        $ErrorUser | Out-File .\NotFoundAAD_$($OutputName) -Append
                        continue
                    }
                }
                
                $FoundUsers.Add($User)
            
            }
            catch {
                Write-Error("Errore nell'aggiunta al Team $($Team.DisplayName) dell'utente $($User.Email)")
                continue
            }
        }
        
        Write-Warning("*** Potrebbero essere necessari alcuni minuti affiché le modifiche diventino visibile nell'applicazione. ***")
        Write-Host("*** Operazione compeltata. Premere un tasto per uscire. ***")
        Read-Host 

    }
    catch {
        Write-Error("Errore.")
    }
}
catch {
    Write-Error("Errore: il team non esiste")
}
