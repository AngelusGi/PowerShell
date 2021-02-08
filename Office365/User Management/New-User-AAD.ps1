# TechNet post https://devblogs.microsoft.com/scripting/use-powershell-to-create-bulk-users-for-office-365/

[CmdletBinding()]
param (
    [Parameter()]
    [TypeName]
    $ParameterName,

    # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
    # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
    # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
    # characters as escape sequences.
    [Parameter(Mandatory=$true,
               Position=0,
               ParameterSetName="LiteralPath",
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Literal path to one or more locations.")]
    [Alias("PSPath")]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $LiteralPath
)

function PrepareEnvironment {

    param(
        [Parameter(Mandatory = $true)]
        [String[]]
        $Modules,
        [int16]
        $Version
    )
    
    process {

        $LibraryURL = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/ModuleManager.ps1"

        $Client = New-Object System.Net.WebClient
    
        $Client.DownloadFile($LibraryURL, "ModuleManager.ps1")

        .\ModuleManager.ps1 -Modules $Modules -CompatibleVersion $Version 

    }
    
}


PrepareEnvironment -Modules "AzureAdPreview","MSOnline"

Connect-AzureAD -TenantDomain "<Tenant_Domain_Name>" # ex. "contoso.onmicorsoft.com"

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

    Write-Output("*** Operazione compeltata su " + $UserPrincipalName + " | psw: " + $UsrPswd + " ***")
    Write-Output("")
    Write-Output("")

}

Write-Output("")
Write-Output("*** OPERAZIONE COMPLETATA ***")
Write-Output("")