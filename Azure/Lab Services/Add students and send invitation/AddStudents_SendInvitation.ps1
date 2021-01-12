# PARAMETERS DESCRIPTION #

# $PathCSV ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
# $Delimiter ex. ';' # Delimitatore del file CSV - valore di default ";" 
# $VmPassword # ex. "Contoso1234@" # Password dell'utente locale della macchina virtuale
# $AzureSubId # ex. "1234-abcd-5678-xxxx-00yyyy" # Azure Subscription Id # Per ottenerlo, usare il comando Connect-AzAccount -> Get-AzSubscription

# END PARAMETERS #

Param
(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]
    $PathCSV,

    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]
    $AzureSubId,

    [parameter(ValueFromPipeline = $true)]
    [String]
    $Delimiter,

    [parameter(ValueFromPipeline = $true)]
    [SecureString]
    $VmPassword    
)


if ([string]::IsNullOrEmpty($Delimiter) -or [string]::IsNullOrWhiteSpace($Delimiter)) {
    $Delimiter = ";"
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
    break
}
elseif ([string]::IsNullOrEmpty($PathCSV) -or [string]::IsNullOrWhiteSpace($PathCSV)) {
    Write-Error("Il parametro PathCSV non può essere vuoto")
    break
}
elseif ([string]::IsNullOrEmpty($AzureSubId) -or [string]::IsNullOrWhiteSpace($AzureSubId)) {
    Write-Error("Il parametro AzureSubId non può essere vuoto")
    break
}
else {
    Write-host("Parametri:")
    Write-host("Path CSV: $($PathCSV)")
    Write-host("Delimitatore del file CSV: $($Delimiter)")
    Write-host("Subscription di Azure: $($AzureSubId)")
    Write-host("Messaggio d'invito: $($InvitationText)")
    Write-Host("***")
}

Write-Warning("Verifica dell'ambiente in corso...")


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

Write-Warning("Verifica moduli in corso...")


if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    Write-Error -Message ('Az module not installed. Having both the AzureRM and Az modules installed at the same time is not supported.')
    Break

}
else {
    Write-Warning("Installazione del modulo Az in corso...")
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}

Write-Warning("Installazione del modulo Az.LabServices in corso...")

$LabServiceLibraryURL = "https://raw.githubusercontent.com/Azure/azure-devtestlab/master/samples/ClassroomLabs/Modules/Library/Az.LabServices.psm1"

$Client = New-Object System.Net.WebClient

$Client.DownloadFile($LabServiceLibraryURL, ".\Az.LabServices.psm1")

Import-Module .\Az.LabServices.psm1

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
