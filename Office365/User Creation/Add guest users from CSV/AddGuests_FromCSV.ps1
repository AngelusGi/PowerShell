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
        [Parameter(Mandatory = $true)]
        [String[]]
        $Modules,
        [int16]
        $Version
    )
    
    process {

        $LibraryURL = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/ModuleManager.ps1"

        $Client = New-Object System.Net.WebClient
    
        $Client.DownloadFile($LibraryURL, ".\ModuleManager.ps1")

        .\ModuleManager.ps1 -Modules $Modules -CompatibleVersion $Version 

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
    Write-Output("Parametri:")
    Write-Output("Path CSV: $($PathCSV)")
    Write-Output("Delimitatore del file CSV: $($Delimiter)")
    Write-Output("Dominio: $($DomainName)")
    Write-Output("***")
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

PrepareEnvironment -Modules "AzureADPreview"

Connect-AzureAD -DomainNameDomain $DomainName

$GuestUsers | ForEach-Object {

    $DisplayName = $_.FirstName + " " + $_.LastName

    New-AzureADMSInvitation -InvitedUserDisplayName $DisplayName -InvitedUserEmailAddress $_.Email -InviteRedirectURL https://portal.office.com -SendInvitationMessage $true
   
    Write-Output("*** Operazione compeltata su $($_.Email) ***")
    Write-Output("")
    Write-Output("")
}

Write-Warning("*** Operazione compeltata ***")
