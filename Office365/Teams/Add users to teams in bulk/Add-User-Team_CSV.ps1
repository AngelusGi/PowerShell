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


function Set-PsEvnironment {
    param(
        [Parameter(
            HelpMessage = "Modules name to install from the GitHub tool repo.",
            Mandatory = $false)]
        [ValidateSet("ModuleManager", "TerraformBackendOnAzure")]
        [string[]]
        $ModulesToInstall = "ModuleManager"
    )

    process {
        $psModuleExtension = "psm1"
    
        foreach ($module in $ModulesToInstall) {

            $libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/$($module)/$($module).$($psModuleExtension)"
            $module = "$($module).$($psModuleExtension)"

            $client = New-Object System.Net.WebClient
            $currentPath = Get-Location
            $downloadPath = Join-Path -Path $currentPath.Path -ChildPath $module
            $client.DownloadFile($libraryUrl, $downloadPath)
            
            $modToImport = Join-Path -Path $currentPath.Path -ChildPath $module -Resolve -ErrorAction Stop
            Import-Module $modToImport -Verbose
            Remove-Item -Path $modToImport -Force
        }
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

Set-PsEvnironment -PsModulesToInstall  "MicrosoftTeams"

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
