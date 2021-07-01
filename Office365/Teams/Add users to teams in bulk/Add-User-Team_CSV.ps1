# PARAMETERS DESCRIPTION #

# $TeamName = "Test Teams CSV 1" # Inserire il nome del team (lo stesso prensente anche nel CSV

# $PathCSV = ".\csv_test.CSV" #Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire

# END PARAMETERS #


Param
(
    [parameter(Mandatory = $true)]
    [String]
    $PathCSV,

    [parameter(Mandatory = $true)]
    [String]
    $TeamName,
    
    [parameter()]
    [String]
    $Delimiter = ";"
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
            HelpMessage = "Scope of the module installation. Default: CurrentUser",
            Mandatory = $false)]
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
}
else {
    Write-Host("Parametri:")
    Write-Host("Path CSV: $($PathCSV)")
    Write-Host("Delimitatore del file CSV: $($Delimiter)")
    Write-Host("Nome del team: $($TeamName)")
    Write-Host("***")
}

Write-Host("Preparazione e verifica dell'ambiente in corso, attendere...")

PrepareEnvironment -ModulesToInstall  "MicrosoftTeams"

Connect-MicrosoftTeams

$team = Get-Team -DisplayName $TeamName

try {
    if ( [string]::IsNullOrWhiteSpace($team) -or [string]::IsNullOrWhiteSpace($team) ) {
        Write-Warning("Il team $($TeamName) non esiste, creazione in corso...")

        New-Team -DisplayName $TeamName

        $IsNotSpread = $True

        do {

            Write-Warning("La propagazione delle modifiche potrebbe richiedere del tempo, attendere...")
            
            $team = Get-Team -DisplayName $TeamName


            if ([string]::IsNullOrEmpty($team) -or [string]::IsNullOrWhiteSpace($team)) {
                $IsNotSpread = $true
                Start-Sleep -Seconds 90   
            }

            $IsNotSpread = $false

            
        } while ($IsNotSpread)
    
    }

    Write-Warning("Team trovato:")

    Write-Host($team)
    
    $guestUsers = Import-Csv $PathCSV -Delimiter $Delimiter

    $guestUsers | ForEach-Object {

        $email = $_.Email

        if ($_.Team.Equals($team.DisplayName)) {
            # $group = Get-Team -MailNickName $TeamName
                
            Add-TeamUser -GroupId $team.GroupId -User $email
            Write-Warning("*** Operazione compeltata su $($email) nel team $($team.DisplayName) ***")
            
        }
        else {
            Write-Error("Errore, nessun team riconosciuto. Il nome team del CSV non è un nome valido.")
        }

        Write-Host("")
        Write-Host("")
    }

}
catch {
    Write-Error("*** ERRORE ***")
}

ExitSessions

Write-Host("Esecuzione script completata.")
