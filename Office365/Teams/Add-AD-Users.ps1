# We are using the preview module of Teams for PowerShell in order to use this method Add-TeamChannelUser - Ref. https://docs.microsoft.com/en-us/powershell/module/teams/Add-TeamChannelUser?view=teams-ps
# Install Teams PowerShell public preview - Ref. https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-install#install-teams-powershell-public-preview

# Expeting those mandatory headers in the CSV file: "Email", "Channel"

# PARAMETERS #

$PathCSV = "<YOUR CSV PATH>" # ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
$Delimiter = "<YOUR DELIMITER IN THE CSV FILE>" # ex. ';' # Delimitatore del file CSV
$TeamName = "<TEAM NAME>" # ex. "Team Contoso"
$Role = "Member" # the deafult member type is "Member", istead of this you can set this parameter as "Owner"

# END PARAMETERS #

$mod = Get-InstalledModule
Write-Output("Preparazione dell'ambiente in corso, attendere...")

foreach ($m in $mod) {
    if (("MicrosoftTeams" -eq $m.Name) -And (-Not "1.1.5-preview" -eq $m.Version)) {
        Uninstall-Module MicrosoftTeams -Force
        Write-Warning("è necessario riavviare powershell e rilanciare lo script, premere un tasto per confermare.")
        Read-Host 
        Exit
    }
}

Install-Module PowerShellGet -Force -AllowClobber
Install-Module MicrosoftTeams -AllowPrerelease -RequiredVersion "1.1.5-preview" -Force
Import-Module MicrosoftTeams

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
                        Write-Error("Il canale $($User.Channel) non esiste")
                        
                        try {
                            New-TeamChannel -GroupId $Team.GroupId -DisplayName $User.Channel
                            Write-Warning("Canale $($User.Channel) creato")
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
            Write-Output("$($User.Email) aggiunto al team $($Team.DisplayName)")

        }
    }
    catch {
        Write-Error("Errore durante l'aggiunta del membro al team!")
    }

    Write-Warning("Operazione in corso, attendere... L'operazione potrebbe richiedere fino a 15 minuti!")
    Start-Sleep -Seconds 840

    foreach ($User in $Users) {

        try {
            $Team = Get-Team -DisplayName $TeamName

            Add-TeamChannelUser -GroupId $Team.GroupId -DisplayName $User.Channel -User $User.Email
            Write-Output("$($User.Email) aggiunto al canale $($User.Channel) del team $($Team.DisplayName)")

            Write-Warning("*** Operazione compeltata su $($User.Email) nel team $($Team.DisplayName) del canale $($User.Channel) ***")
        }
        catch {
            Write-Error("Errore durante l'aggiunta del membro al canale! Verificare di essere loggati come creatore del canale.")

        }
    }
    
}
catch {
    Write-Error("Errore: il team non esiste!")
}
