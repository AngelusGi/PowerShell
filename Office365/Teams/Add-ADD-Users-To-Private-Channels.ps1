# We are using the preview module of Teams for PowerShell in order to use this method Add-TeamChannelUser - Ref. https://docs.microsoft.com/en-us/powershell/module/teams/Add-TeamChannelUser?view=teams-ps
# Install Teams PowerShell public preview - Ref. https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-install#install-teams-powershell-public-preview

# Expeting those mandatory headers in the CSV file: "Email", "Channel" (case sensitive)
# All the members are added to only to private channels

# PARAMETERS #

$PathCSV = "<YOUR CSV PATH>" # ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
$Delimiter = "<YOUR DELIMITER IN THE CSV FILE>" # ex. ';' # Delimitatore del file CSV
$TeamName = "<TEAM NAME>" # ex. "Team Contoso"
$Role = "Member" # the deafult member type is "Member", istead of this you can set this parameter as "Owner"

# END PARAMETERS #

Write-Output("Preparazione e verifica dell'ambiente in corso, attendere...")


try {
    Get-InstalledModule -Name "PowerShellGet"    
}
catch {
    Write-Error("Moduli non trovati, installazione in corso...")
    Install-Module PowerShellGet -AllowClobber -Force
}

try {
    $modTeams = Get-InstalledModule -Name "MicrosoftTeams"
}
catch {
    Write-Error("Moduli non trovati, installazione in corso...")
    Install-Module MicrosoftTeams -AllowPrerelease -RequiredVersion "1.1.5-preview" -Force
}

if (-Not "1.1.5-preview" -eq $modTeams.Version) {
    Uninstall-Module -Name MicrosoftTeams -AllVersions -Force
    Write-Warning("è necessario riavviare powershell e rilanciare lo script, premere un tasto per confermare.")
    Read-Host 
    Exit
} else {
    Get-InstalledModule -Name "MicrosoftTeams"
}

Import-Module -Name MicrosoftTeams -Force


try {

    Connect-MicrosoftTeams

    $FoundUsers = New-Object -TypeName "System.Collections.ArrayList"
    $ErrorUser = $null

    $TempFileName = $PathCSV.Replace(".\", "")
    $FileName = $TempFileName.Replace(".CSV", "")
    $OutputName = "$($FileName).txt"

    Write-Output("Ricerca del Team $($TeamName) in corso, attendere...")
    $Team = Get-Team -DisplayName $TeamName

    if ($null -eq $Team) {
        Write-Error("Il team indicato non esiste $($TeamName)")
        break
    }

    try {
        
        try {
            Write-Output("Verifica del CSV in corso...")
            $Users = Import-Csv $PathCSV -Delimiter $Delimiter

            $ChannelsCSV = $Users.Channel | Select-Object -Unique
        }
        catch {
            Write-Error("Impossibile accedere al CSV, verificare il path e i campi")
            exit
        }
        
        Write-Output("Ricerca dei canali del Team $($TeamName) in corso, attendere...")

        $Channels = Get-TeamChannel -GroupId $Team.GroupId


        foreach ($ChCSV in $ChannelsCSV) {
            $NotFound = $true

            foreach ($Ch in $Channels) {
                if ($Ch.DisplayName -eq $ChCSV) {
                    $NotFound = $false
                    break
                }            
            }

            if ($NotFound) {
                try {
                    Write-Warning("Il canale $($ChCSV) non esiste, creazione in corso, attendere...")
                    New-TeamChannel -GroupId $Team.GroupId -DisplayName $ChCSV -MembershipType "Private"
                    Start-Sleep -Seconds 300
                    Write-Warning("Canale $($ChCSV) creato")
                }
                catch {
                    Write-Error("Impossibile gestire il canale")
                    exit
                }
            }
        }

        $Channels = Get-TeamChannel -GroupId $Team.GroupId
        Write-Output("Canali trovati: $($Channels)")

        Write-Output("Ricerca dei membri gia presenti in corso...")
        $TeamUsers = Get-TeamUser -GroupId $Team.GroupId -Role $Role

        foreach ($User in $Users) {

            try {
                
                $NotFound = $true

                foreach ($TeamUser in $TeamUsers) {
                    if ($TeamUser.User -eq $User.Email) {
                        $NotFound = $false
                        break
                    }

                }
            
                if ($NotFound) {
                    try {
                        $ErrorUser = $User
                        Write-Output("Aggiunta dell'utente $($User.Email) al team $($Team.DisplayName) in corso, attendere...")
                        Add-TeamUser -GroupId $Team.GroupId -User $User.Email
                        Start-Sleep -Seconds 30
                        Write-Output("$($User.Email) aggiunto al team $($Team.DisplayName)")
                        
                    }
                    catch {
                        Write-Error("L'utente $($User.Email) non presente in Microsoft Teams!")
                        $ErrorUser | Out-File .\NotFoundAAD_$($OutputName) -Append
                        continue
                    }
                
                }
                else {
                    $FoundUsers.Add($User)
                }
            
                Write-Output("")

            }
            catch {
                Write-Error("Errore nell'aggiunta al Team $($Team.DisplayName) dell'utente $($User.Email)")
                continue
            }
        }
    

        Write-Warning("Operazione in corso, attendere... L'operazione potrebbe richiedere circa a 30 minuti!")
        # Start-Sleep -Seconds 1800

        Write-Output("Preparazione in corso, attendere...")
        $Team = Get-Team -DisplayName $TeamName

        

        foreach ($User in $FoundUsers) {

            try {

                $ChannelUsers = Get-TeamChannelUser -GroupId $Team.GroupId -DisplayName $User.Channel

                $NotFound = $true

                if (-not $null -eq $ChannelUsers) {
                    foreach ($ChUser in $ChannelUsers) {
                        if ($ChUser.User -eq $User.Email) {
                            $NotFound = $false
                            break
                        }
    
                    }
                }

                if ($NotFound) {
                    try {
                        $ErrorUser = $User
                        Write-Output("Aggiunta dell'utente $($User.Email) al canale $($Team.DisplayName) in corso, attendere...")
                        Add-TeamChannelUser -GroupId $Team.GroupId -DisplayName $User.Channel -User $User.Email
                        Start-Sleep -Seconds 30
                        Write-Output("$($User.Email) aggiunto al canale $($User.Channel) del team $($Team.DisplayName)")
                    }
                    catch {
                        Write-Error("Impossibile aggiungere l'utente al canale!")
                        $ErrorUser | Out-File .\NotAddedChannel_$($OutputName) -Append
                
                        continue
                    }
                
                }

                Write-Warning("*** Operazione compeltata su $($User.Email) nel team $($Team.DisplayName) del canale $($User.Channel) ***")
            }
            catch {
                Write-Error("Errore durante l'aggiunta dell'utente al canale! Verificare di essere loggati come creatore del canale.")

            }
        }
    
    }
    catch {
        Write-Error("Errore.")
    }
}
catch {
    Write-Error("Errore: il team non esiste")

}
