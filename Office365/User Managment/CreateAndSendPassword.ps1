#1.1.0 -> no csv, send the email to a single user

Install-Module MSOnline

$AdUser = "ADMIN EMAIL"
$AdPswd = ConvertTo-SecureString 'ADMIN PSWD' -AsPlainText -Force
$AdminCred = New-Object System.Management.Automation.PSCredential $AdUser, $AdPswd

# currentUser data
$NewUserName = "NEW USER UPN"
# generate random password using these characters -> !”#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_abcdefghijklmnopqrstuvwxyz{|}~0123456789
$NewPswdUser = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..12 | Sort-Object {Get-Random})[0..12] -join ''

# email
$SendEmail = "SENDER EMAIL"
$BackUpEmail = "EMAIL BACKUP OF THE CREATED USER"
$EmailBody = "Ciao $NewUserName ecco la tua password $NewPswdUser"
$EmailSubject = "User Info"
$SMTPServer = smtp.office365.com
$SMTPPort = 587


# New user info
$CountryCode = "IT"
$LinceseSKU = "LICENSE SKU"
$DispalyName = "FULL NAME"
$FirstName = "FIRST NAME"
$LastName = "LAST NAME"

#tenant connection
Connect-MsolService -Credential $AdminCred

#create user
New-MsolUser -DisplayName $DispalyName -FirstName $FirstName -LastName $LastName -UserPrincipalName $NewUserName -UsageLocation $CountryCode -LicenseAssignment $LinceseSKU

#set password
Set-MsolUserPassword –UserPrincipalName $NewUserName –NewPassword $NewPswdUser -ForceChangePassword $True

#$AdminCred = Get-credential

#Send email
Send-MailMessage –From $SendEmail –To  $BackUpEmail –Subject $EmailSubject –Body $EmailBody -SmtpServer $SMTPServer -Credential $AdminCred -UseSsl -Port $SMTPPort
