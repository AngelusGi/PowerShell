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
    [parameter(Mandatory = $true)]
    [String]
    $PathCSV,

    [parameter(Mandatory = $true)]
    [String]
    $DomainName,

    [parameter(Mandatory = $true)]
    [bool]
    $StaticPswd,   

    [parameter()]
    [string]
    $Pswd,

    [parameter()]
    [String]
    $CountryCode = "IT",

    [parameter()]
    [String]
    $Delimiter = ",",

    [parameter()]
    [String]
    $DataLocation = "EUR",

    [parameter()]
    [String]
    $SMTPServer = "smtp.office365.com",

    [parameter()]
    [int]
    $SMTPPort = 587
)


function PrepareEnvironment {

    param(
        [Parameter(
            HelpMessage = "List of modules to be installed.",
            Mandatory = $true)]
        [string[]]
        $ModulesToInstall,
        
        [Parameter(
            HelpMessage = "If true, this script has dependecies in order to be executed only on PowerShell 5.",
            Mandatory = $false)]
        [bool]
        $OnlyPowerShell5 = $false,

        [Parameter(
            HelpMessage = "Scope of the module installation. Default: CurrentUser",
            Mandatory = $false)]
        [string]
        $Scope = "CurrentUser"
    )
    
    process {

        $_customMod = "ModuleManager.psm1"

        $_libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/Module%20Manager/$($_customMod)"

        $_client = New-Object System.Net.WebClient
    
        $_currentPath = Get-Location

        $_moduleFileName = "\$($_customMod)"

        if ([System.Environment]::OSVersion.Platform.Equals("Unix")) {
        $_moduleFileName = "/$($_customMod)"
        }

        $_downloadPath = $_currentPath.Path + $_moduleFileName
        
        $_client.DownloadFile($_libraryUrl, $_downloadPath)

        Import-Module -Name ".$($_moduleFileName)"
        
        Get-EnvironmentInstaller -Modules $ModulesToInstall -CompatibleVersion $OnlyPowerShell5 -Scope $Scope
        
        Remove-Item -Path $_downloadPath -Force
        
    }
    
}


if ([string]::IsNullOrWhiteSpace($Delimiter)) {
    Write-Error("Il parametro Delimiter non può essere vuoto")
    exit

}
elseif ([string]::IsNullOrEmpty($PathCSV) -or [string]::IsNullOrWhiteSpace($PathCSV)) {
    Write-Error("Il parametro PathCSV non può essere vuoto")
    exit

}
elseif ($StaticPswd) {
    if ([string]::IsNullOrEmpty($Pswd) -or [string]::IsNullOrWhiteSpace($Pswd)) {
        Write-Error("Il parametro Pswd non può essere vuoto avendo impostato una password statica (uguale per tutti al primo accesso)")
        exit
    
    }
}
elseif ([string]::IsNullOrEmpty($DomainName) -or [string]::IsNullOrWhiteSpace($DomainName)) {
    Write-Error("Il parametro DomainName non può essere vuoto")
    exit

}


Write-Warning("Parametri immessi:")
Write-Host("Path CSV: $($PathCSV)")
Write-Host("Delimitatore del file CSV: $($Delimiter)")
Write-Host("Nome dominio: $($DomainName)")
Write-Host("Password statica (comune per tutti al primo accesso): $($StaticPswd)")

if ($StaticPswd) {
        
    Write-Host("Passowrd predefinita: $($Pswd)")
}

Write-Host("Country code: $($CountryCode)")
Write-Host("Server SMTP: $($SMTPServer)")
Write-Host("Porta SMTP: $($SMTPPort)")
Write-Host("***")

PrepareModule -Modules "MSOnline", "ExchangeOnlineManagement"

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
