﻿# PARAMETERS #

# $DomainName = "<DomainName_Domain_Name>" # ex. "contoso.onmicrosoft.com"
# $PathCSV = "<CSV PATH>" # ex. ".\csv_test.CSV"
# $Delimiter = '<YOUR Delimiter IN THE CSV FILE>' # ex. ';' or ','

# END PARAMETERS #


Param
(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]
    $DomainName,

    [parameter(ValueFromPipeline = $true)]
    [String]
    $Delimiter,

    [parameter(Mandatory=$true, ValueFromPipeline = $true)]
    [String]
    $PathCSV    
)


if ([string]::IsNullOrEmpty($Delimiter) -or [string]::IsNullOrWhiteSpace($Delimiter)) {
    $Delimiter = ";"
}

if ([string]::IsNullOrWhiteSpace($Delimiter)) {
    Write-Error("Il parametro Delimiter non può essere vuoto")
    break
}
elseif ([string]::IsNullOrEmpty($PathCSV) -or [string]::IsNullOrWhiteSpace($PathCSV)) {
    Write-Error("Il parametro PathCSV non può essere vuoto")
    break
}
elseif ([string]::IsNullOrEmpty($DomainName) -or [string]::IsNullOrWhiteSpace($DomainName)) {
    Write-Error("Il parametro DomainName non può essere vuoto")
    break
}
else {
    Write-host("Parametri:")
    Write-host("Path CSV: $($PathCSV)")
    Write-host("Delimitatore del file CSV: $($Delimiter)")
    Write-host("Dominio: $($DomainName)")
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

Write-Warning("Verifica moduli in corso...")
Write-Warning("Installazione del modulo Az in corso...")

Install-Module AzureADPreview -Force -Verbose -Scope CurrentUser

Connect-AzureAD -DomainNameDomain $DomainName

$GuestUsers | ForEach-Object {

    $DisplayName = $_.FirstName + " " + $_.LastName

    New-AzureADMSInvitation -InvitedUserDisplayName $DisplayName -InvitedUserEmailAddress $_.Email -InviteRedirectURL https://portal.office.com -SendInvitationMessage $true
   
    Write-Host("*** Operazione compeltata su $($_.Email) ***")
    Write-Host("")
    Write-Host("")
}

Write-Warning("*** Operazione compeltata ***")