# PARAMETERS DESCRIPTION #

# $PathCSV ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
# $Delimiter ex. ';' # Delimitatore del file CSV - valore di default ";"
# $VmPassword # ex. "Contoso1234@" # Password dell'utente locale della macchina virtuale
# $AzureSubId # ex. "1234-abcd-5678-xxxx-00yyyy" # Azure Subscription Id # Per ottenerlo, usare il comando Connect-AzAccount -> Get-AzSubscription

# END PARAMETERS #

Param
(
    [parameter(Mandatory = $true)]
    [String]
    $PathCSV,

    [parameter(Mandatory = $true)]
    [String]
    $AzureSubId,

    [parameter()]
    [String]
    $Delimiter = ",",

    [parameter()]
    [SecureString]
    $VmPassword
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
    
        $Client.DownloadFile($LibraryURL, "ModuleManager.ps1")

        .\ModuleManager.ps1 -Modules $Modules -CompatibleVersion $Version 

    }
    
}


if ([string]::IsNullOrEmpty($VmPassword) -or [string]::IsNullOrWhiteSpace($VmPassword)) {
    $InvitationText = "Contatta l'amministratore per avere informazioni circa la password."

}
else {
    $SecurePassword = $VmPassword | ConvertTo-SecureString -AsPlainText -Force
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $InvitationText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}


if ([string]::IsNullOrWhiteSpace($Delimiter)) {
    Write-Error("Il parametro Delimiter non può essere vuoto")
    exit
}
elseif ([string]::IsNullOrEmpty($PathCSV) -or [string]::IsNullOrWhiteSpace($PathCSV)) {
    Write-Error("Il parametro PathCSV non può essere vuoto")
    exit
}
elseif ([string]::IsNullOrEmpty($AzureSubId) -or [string]::IsNullOrWhiteSpace($AzureSubId)) {
    Write-Error("Il parametro AzureSubId non può essere vuoto")
    exit
}
else {
    Write-Output("Parametri:")
    Write-Output("Path CSV: $($PathCSV)")
    Write-Output("Delimitatore del file CSV: $($Delimiter)")
    Write-Output("Subscription di Azure: $($AzureSubId)")
    Write-Output("Messaggio d'invito: $($InvitationText)")
    Write-Output("***")
}


try {

    Write-Warning("Verifica del CSV in corso...")
    $Users = Import-Csv $PathCSV -Delimiter $Delimiter

    ForEach ($email in $Users.Email) {
        if ( [string]::IsNullOrEmpty($email) -or [string]::IsNullOrWhiteSpace($email) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'Email' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }
    }

    ForEach ($labName in $Users.LabName) {
        if ( [string]::IsNullOrEmpty($labName) -or [string]::IsNullOrWhiteSpace($labName) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'LabName' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }
    }


}
catch {
    Write-Error("Impossibile accedere al CSV, verificare il path e i campi")
    exit
}



PrepareEnvironment -Modules "Az","Az.LabServices"

Connect-AzAccount -SubscriptionId $AzureSubId

$Users | ForEach-Object {

    $Lab = Get-AzLabAccount | Get-AzLab -LabName $_.LabName

    Add-AzLabUser  -Lab $Lab -Emails $_.Email
    Write-Warning("*** Aggiunta al laboratorio $($_.LabName) di $($_.Email) completata ***")

}

$Labs = $Users.LabName | Get-Unique

foreach ($Lab in $Labs) {
    $CurrentLab = Get-AzLabAccount | Get-AzLab -LabName $Lab

    $LabUsers = Get-AzLabUser -Lab $CurrentLab

    foreach ($User in $LabUsers) {
        Send-AzLabUserInvitationEmail -User $User -InvitationText $InvitationText -Lab $CurrentLab
        Write-Warning("*** Invito al laboratorio $($CurrentLab.name) inviato a $($User.properties.email) ***")
    }
    
}
