# PARAMETERS #

# $DomainName = "<DomainName_Domain_Name>" # ex. "contoso.onmicrosoft.com"
# $PathCSV = "<CSV PATH>" # ex. ".\csv_test.CSV"
# $Delimiter = '<YOUR Delimiter IN THE CSV FILE>' # ex. ';' or ','

# END PARAMETERS #


Param
(
    [parameter(Mandatory = $true)]
    [String]
    $DomainName,

    [parameter()]
    [String]
    $Delimiter = ";",

    [parameter(Mandatory=$true)]
    [String]
    $PathCSV
)


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
        
    }
    
}



if ([string]::IsNullOrWhiteSpace($Delimiter)) {
    Write-Error("Il parametro Delimiter non può essere vuoto")
    exit
}
elseif ([string]::IsNullOrEmpty($PathCSV) -or [string]::IsNullOrWhiteSpace($PathCSV)) {
    Write-Error("Il parametro PathCSV non può essere vuoto")
    exit
}
elseif ([string]::IsNullOrEmpty($DomainName) -or [string]::IsNullOrWhiteSpace($DomainName)) {
    Write-Error("Il parametro DomainName non può essere vuoto")
    exit
}
else {
    Write-Host("Parametri:")
    Write-Host("Path CSV: $($PathCSV)")
    Write-Host("Delimitatore del file CSV: $($Delimiter)")
    Write-Host("Dominio: $($DomainName)")
    Write-Host("***")
}


Write-Warning("Verifica dell'ambiente in corso...")


try {
            
    Write-Warning("Verifica del CSV in corso...")

    $GuestUsers = Import-Csv $PathCSV -Delimiter $Delimiter
        
    ForEach ($guest in $GuestUsers) {
        if ( [string]::IsNullOrEmpty($guest.Email) -or [string]::IsNullOrWhiteSpace($guest.Email) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'Email' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }

        if ( [string]::IsNullOrEmpty($guest.FirstName) -or [string]::IsNullOrWhiteSpace($guest.FirstName) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'FirstName' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }

        if ( [string]::IsNullOrEmpty($guest.LastName) -or [string]::IsNullOrWhiteSpace($guest.LastName) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'LastName' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }
    }

}
catch {
    Write-Error("Impossibile accedere al CSV, verificare il path e i campi")
    exit
}

PrepareEnvironment -ModulesToInstall  "AzureADPreview"

Connect-AzureAD -DomainNameDomain $DomainName

$GuestUsers | ForEach-Object {

    $DisplayName = $_.FirstName + " " + $_.LastName

    New-AzureADMSInvitation -InvitedUserDisplayName $DisplayName -InvitedUserEmailAddress $_.Email -InviteRedirectURL https://portal.office.com -SendInvitationMessage $true
   
    Write-Host("*** Operazione compeltata su $($_.Email) ***")
    Write-Host("")
    Write-Host("")
}

Write-Warning("*** Operazione compeltata ***")
