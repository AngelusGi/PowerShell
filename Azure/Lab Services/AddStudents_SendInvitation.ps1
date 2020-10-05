# PARAMETERS DESCRIPTION #

# $PathCSV ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
# $Delimiter ex. ';' # Delimitatore del file CSV - valore di default ";" 
# $LabName # ex. "Contoso" # Nome del laboratorio di Azure Lab Services
# $AzSubId # ex. "1234-abcd-5678-xxxx-00yyyy" # Azure Subscription Id # Per ottenerlo, usare il comando Connect-AzAccount -> Get-AzSubscription

# END PARAMETERS #

Param
(
    [parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String]
    $PathCSV,

    [parameter(ValueFromPipeline=$true)]
    [String]
    $Delimiter,

    [parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String]
    $AzureSubId,

    [parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String]
    $LabName
)

if([string]::IsNullOrEmpty($Delimiter) -or [string]::IsNullOrWhiteSpace($Delimiter)){
    $Delimiter = ";"
}


if ([string]::IsNullOrWhiteSpace($Delimiter)) {
    Write-Error("Il parametro Delimiter non può essere vuoto")
    break
} elseif ([string]::IsNullOrEmpty($LabName) -or [string]::IsNullOrWhiteSpace($LabName)) {
    Write-Error("Il parametro LabName non può essere vuoto")
    break
}elseif ([string]::IsNullOrEmpty($PathCSV) -or [string]::IsNullOrWhiteSpace($PathCSV)) {
    Write-Error("Il parametro PathCSV non può essere vuoto")
    break
}else {
    Write-host("Parametri:")
    Write-host("Path CSV: $($PathCSV)")
    Write-host("Delimitatore del file CSV: $($Delimiter)")
    Write-host("Nome del laboratorio: $($LabName)")
    Write-host("Subscription di Azure: $($AzSubId)")
}

Write-Warning("Verifica dell'ambiente in corso...")

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

Select-AzSubscription -SubscriptionId $AzSubId

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

