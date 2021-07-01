# TechNet post https://devblogs.microsoft.com/scripting/use-powershell-to-create-bulk-users-for-office-365/


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


# *** DEFAULT PARAMETERS ****
$Country = "IT" # Country code "IT" = Italy
$DataPref = "EUR"
# *** END DEFAULT PARAMETERS ****


# *** USER DATA ***
# *** MANDATORY PARAMETERS ***
$AdUser = "MY ADMIN" # "MY ADMIN" = admin username of the tenant # ex. "admin@contoso.com"
$AdPswd = ConvertTo-SecureString 'MY PASSWORD' -AsPlainText -Force # 'MY PASSWORD' = admin password of the tenant 
$AdminCred = New-Object System.Management.Automation.PSCredential $AdUser, $AdPswd

$Domain = "MY TENANT DOMAIN" # "MY TENANT DOMAIN" = ex. "@contoso.com" or "@contoso.onmicrosoft.com"
$UsrPswd = "NEW USER PSWD" # "NEW USER PSWD" = default password for all users
$PathCSV = "MY CSV" # "MY CSV" # ex. "C:\csv\users_test.CSV"

$ExpirePswd = $false # if $false password never expires, otherwise insert $true 

$License = "MY LICENSE" # "MY LICENSE" # ex. "contoso:STANDARDWOFFPACK_STUDENT" for students account or "contoso:STANDARDWOFFPACK_FACULTY" for staff and professors
# to obtain the sku avaliable please refer to https://docs.microsoft.com/en-us/powershell/module/msonline/get-msolaccountsku?view=azureadps-1.0

# *** OPTIONAL PARATMETRS ***
$Role = "MY ROLE" # "MY ROLE" User role's in this CSV # ex. "Docente" or "Studente" - if you wont use it set as ""
$Class  = "MY DEPARTMENT" # "MY DEPARTMENT" it can be used for identify student's class # ex. "1D" - if you wont use it set as ""
# *** END USER DATA ***

PrepareEnvironment -ModulesToInstall  "MSOnline"

Connect-MsolService -Credential $AdminCred

$users = Import-Csv $PathCSV

$users | ForEach-Object {

    # I use a CSV header "UPN,Nome,Cognome,Department", to use the CSV field use this sintax $_.Field
    # Username or UPN, Nome, Cognome are mandatory in your CSV
    $Displayname = $_.Nome + "" + $_.Cognome
    $UserPrincipalName = $_.UPN + $Domain
    
    # add the user
    # for details see this reference: https://docs.microsoft.com/en-us/powershell/module/msonline/new-msoluser?view=azureadps-1.0
    New-MsolUser
        # *** IF YOU WANT TO ADD MORE PARAMETER ADD IT HERE *** 
        -FirstName $_.Nome
        -LastName $_.Cognome
        # *** DO NOT MODIFY THE FOLLOWING PARAMETERS *** 
        -UserPrincipalName $UserPrincipalName
        -DisplayName $Displayname
        -Title $Role    
        -Department $Class
        -PreferredDataLocation $DataPref
        -UsageLocation $Country
        -LicenseAssignment $License
        -PasswordNeverExpires $ExpirePswd
    
    # set the password for the current user - at the first access the user have to change the default password
    # for details see this reference: https://docs.microsoft.com/en-us/powershell/module/msonline/set-msoluserpassword?view=azureadps-1.0
    Set-MsolUserPassword –UserPrincipalName $UserPrincipalName –NewPassword $UsrPswd -ForceChangePassword $True

    Write-Host("*** Operazione compeltata su " + $UserPrincipalName + " | psw: " + $UsrPswd + " ***")
    Write-Host("")
    Write-Host("")

}

Write-Host("")
Write-Host("*** OPERAZIONE COMPLETATA ***")
Write-Host("")
