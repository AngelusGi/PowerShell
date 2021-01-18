# We are using the preview module of Teams for PowerShell in order to use this method Add-TeamChannelUser - Ref. https://docs.microsoft.com/en-us/powershell/module/teams/Add-TeamChannelUser?view=teams-ps
# Install Teams PowerShell public preview - Ref. https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-install#install-teams-powershell-public-preview

# Expeting those mandatory headers in the CSV file: "Email", "Channel" (case sensitive)
# All the members are added to only to private channels

# PARAMETERS #

# $PathCSV = "<YOUR CSV PATH>" # ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
# $Delimiter = "<YOUR DELIMITER IN THE CSV FILE>" # ex. ';' # Delimitatore del file CSV
# $TeamName = "<TEAM NAME>" # ex. "Team Contoso"
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


Write-Output("Preparazione e verifica dell'ambiente in corso, attendere...")

try {
    $PSTeamsModule = "MicrosoftTeams"

    $ModTeams = Get-InstalledModule -Name $PSTeamsModule

    if ($null -eq $ModTeams) {
        Install-Module -Name $PSTeamsModule -AllowPrerelease -RequiredVersion "1.1.5-preview" -Force
    }
    
    if (-Not "1.1.5-preview" -eq $ModTeams.Version) {
        Uninstall-Module -Name $PSTeamsModule -AllVersions -AcceptLicense -Force
        Write-Warning("è necessario riavviare powershell e rilanciare lo script, premere un tasto per confermare.")
        Read-Host
        Exit
    }
}
catch {
    Write-Error("Modulo $($PSTeamsModule) non trovato...")
    break
}

Import-Module -Name $PSTeamsModule

Write-Output("Riepilogo moduli trovati")
Get-InstalledModule -Name $PSTeamsModule

Connect-MicrosoftTeams


try {


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

            ForEach ($User in $Users) {
                if ( [string]::IsNullOrEmpty($User.Email) -or [string]::IsNullOrWhiteSpace($User.Email) ) {
                    Write-Error("Il CSV non è formattato correttamente, verificare il campo 'Email' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
                    exit
                }

                if ( [string]::IsNullOrEmpty($User.Channel) -or [string]::IsNullOrWhiteSpace($User.Channel) ) {
                    Write-Error("Il CSV non è formattato correttamente, verificare il campo 'Channel' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
                    exit
                }
            }

        }
        catch {
            Write-Error("Impossibile accedere al CSV, verificare il path e i campi")
            exit
        }
        
        Write-Output("Ricerca dei canali del Team $($TeamName) in corso, attendere...")

        $ChannelsCSV = $Users.Channel | Select-Object -Unique
        $Channels = Get-TeamChannel -GroupId $Team.GroupId

        foreach ($ChCSV in $ChannelsCSV) {

            if (-not $Channels.DisplayName.Contains($ChCSV)) {

                try {
                    Write-Warning("Il canale $($ChCSV) non esiste, creazione in corso, attendere...")
                    New-TeamChannel -GroupId $Team.GroupId -DisplayName $ChCSV -MembershipType "Private"
                    Start-Sleep -Seconds 300
                    Write-Warning("Canale $($ChCSV) creato")
                }
                catch {
                    Write-Error("Impossibile gestire il canale $($ChCSV)")
                    exit
                }
            }
            
        }

        Write-Output("Ricerca dei membri gia presenti nel team $($Team.DisplayName) in corso...")
        $TeamUsers = Get-TeamUser -GroupId $Team.GroupId -Role $Role

        foreach ($User in $Users) {

            try {

                if (-not $TeamUsers.User.Contains($User.Email)) {
                    try {
                        $ErrorUser = $User
                        Write-Output("Aggiunta dell'utente $($User.Email) al team $($Team.DisplayName) in corso, attendere...")
                        Add-TeamUser -GroupId $Team.GroupId -User $User.Email
                        Start-Sleep -Seconds 45
                        Write-Output("$($User.Email) aggiunto al team $($Team.DisplayName)")
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

        $Team = Get-Team -DisplayName $TeamName

        $IsNotSpread = $True

        do {

            Write-Warning("La propagazione delle modifiche potrebbe richiedere del tempo, attendere...")
            
            $SpreadUsers = Get-TeamUser -GroupId $Team.GroupId -Role $Role

            foreach ($FoundUserEmail in $FoundUsers.Email) {
                if (-not $SpreadUsers.User.Contains($FoundUserEmail)) {
                    $IsNotSpread = $true
                    break
                }
                else {
                    $IsNotSpread = $false
                }
            }

            $SpreadChannels = Get-TeamChannel -GroupId $Team.GroupId
            
            $ChannelsCSV = $Users.Channel | Select-Object -Unique

            foreach ($ChannelCSV in $ChannelsCSV) {
                if (-not $SpreadChannels.DisplayName.Contains($ChannelCSV)) {
                    $IsNotSpread = $true
                    break
                }
                else {
                    $IsNotSpread = $false
                }
            }

            Start-Sleep -Seconds 90

        } while ($IsNotSpread)
    

        Write-Output("Modifiche propagate. Raccolta delle informazioni necessarie in corso, attendere...")

        $Channels = Get-TeamChannel -GroupId $Team.GroupId
        Write-Output("Canali trovati:")
        Write-Output("$($Channels.DisplayName)")

        $Team = Get-Team -DisplayName $TeamName


        foreach ($User in $FoundUsers) {

            try {

                $ChannelUsers = Get-TeamChannelUser -GroupId $Team.GroupId -DisplayName $User.Channel

                if (-not $null -eq $ChannelUsers) {
                    if ($ChannelUsers.User.Contains($User.Email)) {
                        try {
                            $ErrorUser = $User
                            Write-Output("Aggiunta dell'utente $($User.Email) al canale $($User.Channel) del team $($Team.DisplayName) in corso, attendere...")
                            Add-TeamChannelUser -GroupId $Team.GroupId -DisplayName $User.Channel -User $User.Email
                            Start-Sleep -Seconds 45
                            Write-Output("$($User.Email) aggiunto al canale $($User.Channel) del team $($Team.DisplayName)")
                        }
                        catch {
                            Write-Error("Impossibile aggiungere l'utente al canale!")
                            $ErrorUser | Out-File .\NotAddedChannel_$($OutputName) -Append
                    
                            continue
                        }
                    }
                    else {
                        try {
                            $ErrorUser = $User
                            Write-Output("Aggiunta dell'utente $($User.Email) al canale $($User.Channel) del team $($Team.DisplayName) in corso, attendere...")
                            Add-TeamChannelUser -GroupId $Team.GroupId -DisplayName $User.Channel -User $User.Email
                            Start-Sleep -Seconds 45
                            Write-Output("$($User.Email) aggiunto al canale $($User.Channel) del team $($Team.DisplayName)")
                        }
                        catch {
                            Write-Error("Impossibile aggiungere l'utente al canale!")
                            $ErrorUser | Out-File .\NotAddedChannel_$($OutputName) -Append
                    
                            continue
                        }
                    }
                }

                Write-Warning("*** Operazione compeltata su $($User.Email) nel team $($Team.DisplayName) del canale $($User.Channel) ***")
            }
            catch {
                Write-Error("Errore durante l'aggiunta dell'utente al canale! Verificare di essere loggati come creatore del canale.")

            }
        }
        
        Write-Warning("*** Potrebbero essere necessari alcuni minuti affiché le modifiche diventino visibile nell'applicazione. ***")
        Write-Output("*** Operazione compeltata. Premere un tasto per uscire. ***")
        Read-Host 

    }
    catch {
        Write-Error("Errore.")
    }
}
catch {
    Write-Error("Errore: il team non esiste")
}