# PARAMETRI DA MODIFICARE #

$DomainName = "<DomainName_Domain_Name>" # ex. "contoso.onmicrosoft.com"
$PathCSV = "<CSV PATH>" # ex. ".\csv_test.CSV"
$Delimiter = '<YOUR Delimiter IN THE CSV FILE>' # ex. ';' or ','

# FINE PARAMETRI DA MODIFICARE #


Install-Module AzureADPreview -Force -Verbose

Connect-AzureAD -DomainNameDomain $DomainName

$GuestUsers = Import-Csv $PathCSV -Delimiter $Delimiter

$GuestUsers | ForEach-Object {

    New-AzureADMSInvitation -InvitedUserDisplayName $_.FullName -InvitedUserEmailAddress $_.Email -InviteRedirectURL https://portal.office.com -SendInvitationMessage $true
   
    Write-Host("*** Operazione compeltata su '" + $_.Email + "' ***")
    Write-Host("")
    Write-Host("")
}