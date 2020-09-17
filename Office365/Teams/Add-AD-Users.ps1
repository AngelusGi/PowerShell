# Expeting those mandatory headers in the CSV file: email | channel

# PARAMETERS #

$PathCSV = "<YOUR CSV PATH>" # ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire

$Delimiter = "<YOUR DELIMITER IN THE CSV FILE>" # ex. ';' # Delimitatore del file CSV

$TeamName = "<TEAM NAME>" # ex. "Team Contoso"

$Role = "Member" # the deafult member type is "Member", istead of this you can set this parameter as "Owner"

# END PARAMETERS #


Install-Module MicrosoftTeams
Import-Module MicrosoftTeams

Connect-MicrosoftTeams

try {
    $Team = Get-Team -DisplayName $TeamName

    try {
        $Users = Import-Csv $PathCSV -Delimiter $Delimiter

        $Users | ForEach-Object {
            
            # Add-TeamUser -GroupId $Team.GroupId -User $_.Email -Role $Role

            Add-TeamChannelUser -GroupId $Team.GroupId -DisplayName $_.Channel -User $_.Email -Role $Role
        
            Write-Warning("*** Operazione compeltata su '$($_.Email)' nel team '$($Team.DisplayName)' ***")
        }
    }
    catch {
        Write-Error("Errore durante l'aggiunta del membro al canale!")
        
    }
    
}
catch {
    Write-Error("Errore: il team non esiste!")
}

