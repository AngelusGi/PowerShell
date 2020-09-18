# Expeting those mandatory headers in the CSV file: email | channel

# PARAMETERS #

$PathCSV = "<YOUR CSV PATH>" # ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
$Delimiter = "<YOUR DELIMITER IN THE CSV FILE>" # ex. ';' # Delimitatore del file CSV
$TeamName = "<TEAM NAME>" # ex. "Team Contoso"
$Role = "Member" # the deafult member type is "Member", istead of this you can set this parameter as "Owner"

# END PARAMETERS #

Install-Module PowerShellGet -Force -AllowClobber
Install-Module MicrosoftTeams -AllowPrerelease -RequiredVersion "1.1.3-preview" -Force
Import-Module MicrosoftTeams -RequiredVersion 1.1.3 -Force

Connect-MicrosoftTeams

try {
    $Team = Get-Team -DisplayName $TeamName

    if ($null -eq $Team) {
        Write-Error("Il team indicato non esiste $($TeamName)")
        break
    }

    try {

        $Users = Import-Csv $PathCSV -Delimiter $Delimiter

        foreach ($User in $Users) {

            try {
                $Channels = Get-TeamChannel -GroupId $Team.GroupId 
                
                foreach ($Ch in $Channels) {
                    if (-Not $Ch.DisplayName -eq $User.Channel) {
                        Write-Error("Il canale indicato non esiste $($User.Channel)")
                        
                        try {
                            New-TeamChannel -GroupId $Team.GroupId -DisplayName $User.Channel
                            Write-Warning("Canale $($User.Channel) creato correttamente")
                        }
                        catch {
                            Write-Error("Impossibile gestire il canale")
                        }
                    }
                    else {
                        Write-Output("*** Canale trovato: $($Ch.DisplayName) ***")
                    }
                }
            }
            catch {
                Write-Error("Errore.")
            }  
            

            Add-TeamUser -GroupId $Team.GroupId -User $User.Email -Role $Role

            Add-TeamChannelUser -GroupId $Team.GroupId -DisplayName $User.Channel -User $User.Email

            Write-Warning("*** Operazione compeltata su '$($_.Email)' nel team '$($Team.DisplayName)' del canale '$($Team.DisplayName)'  ***")
        }
    }
    catch {
        Write-Error("Errore durante l'aggiunta del membro al canale!")
    }
    
}
catch {
    Write-Error("Errore: il team non esiste!")
}

