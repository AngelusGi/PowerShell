# PARAMETERS #

$PathCSV = "<YOUR CSV PATH>" # ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire

$Delimiter = "<YOUR DELIMITER IN THE CSV FILE>" # ex. ';' # Delimitatore del file CSV

$LabName = "<LAB NAME>" # ex. "Contoso" # Nome del laboratorio di Azure Lab Services

$SubId = "<YOUR AZURE SUBSCRIPTION ID>" # ex. "1234-abcd-5678-xxxx-00yyyy" # Azure Subscription Id # Per ottenerlo, usare il comando Connect-AzAccount -> Get-AzSubscription

# END PARAMETERS #



if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    Write-Error -Message ('Az module not installed. Having both the AzureRM and Az modules installed at the same time is not supported.')
    Break

} else {
    Write-Warning("Installazione del modulo Az in corso...")
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}

Write-Warning("Installazione del modulo Az.LabServices in corso...")

$LabServiceLibraryURL = "https://raw.githubusercontent.com/Azure/azure-devtestlab/master/samples/ClassroomLabs/Modules/Library/Az.LabServices.psm1"

$Client = New-Object System.Net.WebClient

$Client.DownloadFile($LabServiceLibraryURL,".\Az.LabServices.psm1")

Import-Module .\Az.LabServices.psm1

Connect-AzAccount

Select-AzSubscription -SubscriptionId $SubId

$Lab = Get-AzLabAccount | Get-AzLab -LabName $LabName

$Users = Import-Csv $PathCSV -Delimiter $Delimiter

$Users | ForEach-Object {

    Add-AzLabUser  -Lab $Lab -Emails $_.Email
    Write-Warning("*** Aggiunta al laboratorio $($Lab.name) di $($_.Email) completata ***")

}


$LabUsers = Get-AzLabUser -Lab $Lab

$LabUsers | ForEach-Object{

    Send-AzLabUserInvitationEmail -Lab $Lab -User $_
    Write-Warning("*** Invito al laboratorio $($Lab.name) inviato a $($_.properties.email) ***")

}

