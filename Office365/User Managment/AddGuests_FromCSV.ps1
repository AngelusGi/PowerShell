# PARAMETRI DA MODIFICARE #

$tenant = "<Tenant_Domain_Name>" # ex. "contoso.onmicrosoft.com"
$csv = "<CSV PATH>" # ex. ".\csv_test.CSV"
$delimiter = '<YOUR DELIMITER IN THE CSV FILE>' # ex. ';' or ','

# FINE PARAMETRI DA MODIFICARE #


Install-Module AzureADPreview -Force -Verbose

Connect-AzureAD -TenantDomain $tenant

$PathCSV = $csv

$guestUsers = Import-Csv $PathCSV -Delimiter $delimiter

$guestUsers | ForEach-Object {

    $email = $_.Email
    New-AzureADMSInvitation -InvitedUserDisplayName $_.FullName -InvitedUserEmailAddress $email -InviteRedirectURL https://portal.office.com -SendInvitationMessage $true
   
    Write-Host("*** Operazione compeltata su '" + $email + "' ***")
    Write-Host("")
    Write-Host("")
}