# PARAMETERS DESCRIPTION #

# $PathCSV # ex. ".\csv_test.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
# $Delimiter # ex. ';' # Delimitatore del file CSV - valore di default ";" 
# $DomainName # ex. "Contoso.onmicrosoft.com" or "Constoso.com" # tenant domain
# $StaticPswd # $true or $false # ex. if $true all the users will use the same password at the first login, otherwise the script will generate a new password
# $Pswd # ex. "Contoso1234@" # if $StaticPswd = $true insert here your password 
# $CountryCode # default -> "IT" # User's country code 
# $SMTPServer # Server SMTP from which send emails # default -> "smtp.office365.com"
# $SMTPPort # Port of the SMTP server # default -> 587

# END PARAMETERS #

Param
(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]
    $PathCSV,

    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]
    $DomainName,

    [parameter(Mandatory = $true)]
    [bool]
    $StaticPswd,   

    [parameter(ValueFromPipeline = $true)]
    [string]
    $Pswd,

    [parameter(ValueFromPipeline = $true)]
    [String]
    $CountryCode,

    [parameter(ValueFromPipeline = $true)]
    [String]
    $Delimiter,

    [parameter(ValueFromPipeline = $true)]
    [String]
    $DataLocation,

    [parameter(ValueFromPipeline = $true)]
    [String]
    $SMTPServer,

    [parameter(ValueFromPipeline = $true)]
    [int]
    $SMTPPort
)


if ([string]::IsNullOrEmpty($Delimiter) -or [string]::IsNullOrWhiteSpace($Delimiter)) {
    $Delimiter = ";"
}

if ([string]::IsNullOrEmpty($DataLocation) -or [string]::IsNullOrWhiteSpace($DataLocation)) {
    $DataLocation = "EUR"
}

if ([string]::IsNullOrEmpty($CountryCode) -or [string]::IsNullOrWhiteSpace($CountryCode)) {
    $CountryCode = "IT"
}

if ([string]::IsNullOrEmpty($SMTPServer) -or [string]::IsNullOrWhiteSpace($SMTPServer)) {
    $SMTPServer = "smtp.office365.com"
}

if ($SMTPPort -eq 0) {
    $SMTPPort = 587
}


if ([string]::IsNullOrWhiteSpace($Delimiter)) {
    Write-Error("Il parametro Delimiter non può essere vuoto")
    break

}
elseif ([string]::IsNullOrEmpty($PathCSV) -or [string]::IsNullOrWhiteSpace($PathCSV)) {
    Write-Error("Il parametro PathCSV non può essere vuoto")
    break

}
elseif ($StaticPswd) {
    if ([string]::IsNullOrEmpty($Pswd) -or [string]::IsNullOrWhiteSpace($Pswd)) {
        Write-Error("Il parametro Pswd non può essere vuoto avendo impostato una password statica (uguale per tutti al primo accesso)")
        break
    
    }
}
elseif ([string]::IsNullOrEmpty($DomainName) -or [string]::IsNullOrWhiteSpace($DomainName)) {
    Write-Error("Il parametro DomainName non può essere vuoto")
    break

}


Write-Warning("Parametri immessi:")
Write-host("Path CSV: $($PathCSV)")
Write-host("Delimitatore del file CSV: $($Delimiter)")
Write-host("Nome dominio: $($DomainName)")
Write-host("Password statica (comune per tutti al primo accesso): $($StaticPswd)")

if ($StaticPswd) {
        
    Write-host("Passowrd predefinita: $($Pswd)")
}

Write-host("Country code: $($CountryCode)")
Write-host("Server SMTP: $($SMTPServer)")
Write-host("Porta SMTP: $($SMTPPort)")
Write-Host("***")

Write-Warning("Verifica dell'ambiente in corso...")

Install-Module MSOnline, ExchangeOnlineManagement -Scope CurrentUser

Get-InstalledModule -Name MSOnline, ExchangeOnlineManagement

Import-Module MSOnline, ExchangeOnlineManagement

try {
    #tenant connection
    $Auth = Get-Credential 
    Connect-MsolService -Credential $Auth
    Connect-ExchangeOnline -Credential $Auth
}
catch {
    Write-Error("Credenziali errate. Riprovare")
    exit
}


try {
            
    Write-Warning("Verifica del CSV in corso...")
    $Users = Import-Csv $PathCSV -Delimiter $Delimiter
    
    ForEach ($User in $Users) {

        if ( [string]::IsNullOrEmpty($User.BackupEmail) -or [string]::IsNullOrWhiteSpace($User.BackupEmail) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'BackupEmail' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }

        if ( [string]::IsNullOrEmpty($User.FirstName) -or [string]::IsNullOrWhiteSpace($User.FirstName) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'FirstName' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }

        if ( [string]::IsNullOrEmpty($User.LastName) -or [string]::IsNullOrWhiteSpace($User.LastName) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'LastName' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }

        if ( [string]::IsNullOrEmpty($User.LinceseSKU) -or [string]::IsNullOrWhiteSpace($Users.LinceseSKU) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'LinceseSKU' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }

    }

}
catch {
    Write-Error("Impossibile accedere al CSV, verificare il path e i campi")
    exit
}


Write-Warning("Preparazione dell'ambiente in corso...")
Set-TransportConfig -SmtpClientAuthenticationDisabled $false
Set-CASMailbox -Identity $Auth.UserName -SmtpClientAuthenticationDisabled $true
Start-Sleep -Seconds 45


foreach ($User in $Users) {

    try {
        $ErrorUser = $User

        $DisplayName = $User.FirstName + " " + $User.LastName

        $_firstName = $User.FirstName -replace '[^\p{L}]', ''
        $_lastName = $User.LastName -replace '[^\p{L}]', ''

        $_upn = $_firstName + "." + $_lastName
    
        $Upn = $_upn + "@" + $DomainName

        if (-not $StaticPswd) {
            # generate random password using these characters -> !”#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_abcdefghijklmnopqrstuvwxyz{|}~0123456789
            $Pswd = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..12 | Sort-Object { Get-Random })[0..12] -join ''
        }


        #create user
        New-MsolUser -DisplayName $DisplayName -FirstName $User.FirstName -LastName $User.LastName -UserPrincipalName $Upn -Password $Pswd -UsageLocation $CountryCode -LicenseAssignment $User.LinceseSKU -PreferredDataLocation $DataLocation

        Start-Sleep -Seconds 45
        Write-Warning("Utente creato: $($DisplayName) | $($Upn)")

        #Send email
        $EmailBody = "Ciao $($DisplayName) ecco la tua password $($Pswd) per l'account $($Upn). Al primo accesso dovrai modificare la password che ti è stata inviata."
        $EmailSubject = "Utente creato in $($DomainName)"

        Send-MailMessage -From $Auth.UserName -To $User.BackUpEmail -Subject $EmailSubject -Body $EmailBody -SmtpServer $SMTPServer -Credential $Auth -Port $SMTPPort -DeliveryNotificationOption "OnFailure" -Priority "High" -UseSsl 
    
    }
    catch {
        Write-Error("Impossibile aggiungere creare l'utente!")
        $ErrorUser | Out-File .\ReportUtentiNonCreati.txt -Append

        continue
    }

}


Set-TransportConfig -SmtpClientAuthenticationDisabled $false
Set-CASMailbox -Identity $Auth.UserName -SmtpClientAuthenticationDisabled $false

Write-Warning("Operazione completata.")
