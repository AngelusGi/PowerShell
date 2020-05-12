#1.1.0

$AdUser = "ADMIN USERNAME"
$AdPswd = ConvertTo-SecureString 'ADMIN PSWD' -AsPlainText -Force
$AdminCred = New-Object System.Management.Automation.PSCredential $AdUser, $AdPswd

#tenant connection
Connect-MsolService -Credential $AdminCred

# CSV Header Template
# UserPrincipalName,FirstName,LastName,DisplayName,JobTitle,Department,OfficeNumber,OfficePhone,MobilePhone,Fax,Address,City,Province,ZIP,Country

# "INPUT CSV PATH, NAME.CSV"
$InputCsvFile = "CSV PATH"

# "OUTPUT CSV PATH, NAME.CSV"
$OutputCsvFile = "CSV PATH"

# "LICENSE SKU OR $null"
$LicenseSKU = "LICENSE SKU"

$CountryCode = "IT"

$ChangePassword = $true

# Get-MSOLUser | Where-Object { $_.isLicensed -eq "True"} | Select-Object DisplayName, UserPrincipalName, isLicensed | Export-Csv C:\Temp\LicensedUsers.csv

Import-Csv -Path $InputCsvFile | ForEach-Object {

    Write-Host ("Processing user: " + $_.UserPrincipalName); 

    New-MsolUser -UserPrincipalName $_.UserPrincipalName -DisplayName $_.DisplayName -FirstName $_.FirstName -LastName $_.LastName -UsageLocation $CountryCode -MobilePhone $_.MobilePhone -Fax $_.Fax -City $_.City -Country $_.Country -PostalCode $_.ZIP -State $_.Province -Office $_.OfficeNumber -StreetAddress $_.Address  -Department $_.Department -PhoneNumber $_.OfficePhone -Title $_.JobTitle -ForceChangePassword $ChangePassword -LicenseAssignment $LicenseSKU

    Write-Host("")

} | Export-Csv -Path $OutputCsvFile

Write-Host " *** OPERAZIONE COMPLETATA *** "
