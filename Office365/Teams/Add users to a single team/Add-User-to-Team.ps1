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


PrepareEnvironment -Modules "MicrosoftTeams"

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

ExitSessions

Write-Host("Esecuzione script completata.")
