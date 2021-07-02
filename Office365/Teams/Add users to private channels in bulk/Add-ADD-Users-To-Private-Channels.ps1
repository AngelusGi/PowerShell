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
    [parameter(Mandatory=$true)]
    [String]
    $PathCSV,

    [parameter(Mandatory=$true)]
    [String]
    $TeamName,

    [parameter()]
    [String]
    $Delimiter = ";",

    [parameter()]
    [String]
    $Role = "Member"
)

function ExitSessions {

    process {
        Disconnect-MicrosoftTeams -Confirm:$false
    }
    
}

function PrepareEnvironment {

    param(
        [Parameter(
            HelpMessage = "List of modules to be installed.",
            Mandatory = $true)]
        [string[]]
        $ModulesToInstall,
        
        [Parameter(
            HelpMessage = "If true, this script has dependecies in order to be executed only on PowerShell 5.",
            Mandatory = $false)]
        [bool]
        $OnlyPowerShell5 = $false,

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

        $_moduleFileName = "\$($_customMod)"

        if ([System.Environment]::OSVersion.Platform.Equals("Unix")) {
        $_moduleFileName = "/$($_customMod)"
        }

        $_downloadPath = $_currentPath.Path + $_moduleFileName
        
        $_client.DownloadFile($_libraryUrl, $_downloadPath)

        Import-Module -Name ".$($_moduleFileName)"
        
        Get-EnvironmentInstaller -Modules $ModulesToInstall -CompatibleVersion $OnlyPowerShell5 -Scope $Scope
        
        Remove-Item -Path $_downloadPath -Force
        
    }
    
}


if ([string]::IsNullOrWhiteSpace($Delimiter)) {
    throw "Il parametro Delimiter non può essere vuoto"
    exit
} elseif ([string]::IsNullOrWhiteSpace($TeamName)) {
    throw "Il parametro TeamName non può essere vuoto"
    exit
}elseif ([string]::IsNullOrWhiteSpace($PathCSV)) {
    throw "Il parametro PathCSV non può essere vuoto"
    exit
}elseif ([string]::IsNullOrWhiteSpace($Role)) {
    throw "Il parametro Role non può essere vuoto"
    exit
}else {
    Write-Host("Riepilogo parametri:")
    Write-Host("Path CSV: $($PathCSV)")
    Write-Host("Delimitatore del file CSV: $($Delimiter)")
    Write-Host("Nome del team: $($TeamName)")
    Write-Host("Ruolo nel team: $($Role)")
    Write-Host("***")

}

PrepareEnvironment -ModulesToInstall "MicrosoftTeams"

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
        Write-Error("Il team indicato non esiste $($TeamName)")
        exit
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
        
        Write-Host("Ricerca dei canali del Team $($TeamName) in corso, attendere...")

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

        Write-Host("Ricerca dei membri gia presenti nel team $($Team.DisplayName) in corso...")
        $TeamUsers = Get-TeamUser -GroupId $Team.GroupId -Role $Role

        foreach ($User in $Users) {

            try {

                if (-not $TeamUsers.User.Contains($User.Email)) {
                    try {
                        $ErrorUser = $User
                        Write-Host("Aggiunta dell'utente $($User.Email) al team $($Team.DisplayName) in corso, attendere...")
                        Add-TeamUser -GroupId $Team.GroupId -User $User.Email
                        Start-Sleep -Seconds 45
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

        $Team = Get-Team -DisplayName $TeamName

        $IsNotSpread = $True

        do {

            Write-Warning("La propagazione delle modifiche potrebbe richiedere del tempo, attendere...")
            
            $SpreadUsers = Get-TeamUser -GroupId $Team.GroupId -Role $Role

            foreach ($FoundUserEmail in $FoundUsers.Email) {
                if (-not $SpreadUsers.User.Contains($FoundUserEmail)) {
                    $IsNotSpread = $true
                    exit
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
                    exit
                }
                else {
                    $IsNotSpread = $false
                }
            }

            Start-Sleep -Seconds 90

        } while ($IsNotSpread)
    

        Write-Host("Modifiche propagate. Raccolta delle informazioni necessarie in corso, attendere...")

        $Channels = Get-TeamChannel -GroupId $Team.GroupId
        Write-Host("Canali trovati:")
        Write-Host("$($Channels.DisplayName)")

        $Team = Get-Team -DisplayName $TeamName

        foreach ($User in $FoundUsers) {

            try {

                $ChannelUsers = Get-TeamChannelUser -GroupId $Team.GroupId -DisplayName $User.Channel

                if (-not $null -eq $ChannelUsers) {
                    if ($ChannelUsers.User.Contains($User.Email)) {
                        try {
                            $ErrorUser = $User
                            Write-Host("Aggiunta dell'utente $($User.Email) al canale $($User.Channel) del team $($Team.DisplayName) in corso, attendere...")
                            Add-TeamChannelUser -GroupId $Team.GroupId -DisplayName $User.Channel -User $User.Email
                            Start-Sleep -Seconds 45
                            Write-Host("$($User.Email) aggiunto al canale $($User.Channel) del team $($Team.DisplayName)")
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
                            Write-Host("Aggiunta dell'utente $($User.Email) al canale $($User.Channel) del team $($Team.DisplayName) in corso, attendere...")
                            Add-TeamChannelUser -GroupId $Team.GroupId -DisplayName $User.Channel -User $User.Email
                            Start-Sleep -Seconds 45
                            Write-Host("$($User.Email) aggiunto al canale $($User.Channel) del team $($Team.DisplayName)")
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

ExitSessions

Write-Host("Esecuzione script completata.")
