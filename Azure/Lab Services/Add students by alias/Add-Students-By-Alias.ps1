<# TEST PURPOSE

$userName = 
$userPassword = 

$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force

$cred = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

$PathCSV = 

#>


# PARAMETERS DESCRIPTION #

# $PathCSV ex. ".\Add-Students-By-Alias.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
# $Delimiter ex. ',' # Delimitatore del file CSV - valore di default ","
# $AzureSub # ex. "1234-abcd-5678-xxxx-00yyyy" or "My Subscription" # Azure Subscription Id or Name # Per ottenerlo, usare il comando Connect-AzAccount -> Get-AzSubscription
# $SendInvitation -> if its value is "$true" the script will invite users to ALS
# $WelcomeMessage -> you can use this parameter to send a custom message to users

# END PARAMETERS #

Param
(
    [parameter(Mandatory = $true)]
    [String]
    $PathCSV,

    [parameter()]
    [String]
    $AzureSub,

    [parameter()]
    [String]
    $Delimiter,
    
    [parameter()]
    [string]
    [ValidateSet('$false', '$true')]
    $SendInvitation = $false,

    [parameter()]
    [String]
    $WelcomeMessaege,

    [parameter()]
    [String]
    $LabName

)

# Region module manager

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
    
        $currentPath = Get-Location

        $downloadPath = $currentPath.Path + "\ModuleManager.ps1"
        
        $Client.DownloadFile($LibraryURL, $downloadPath)

        .\ModuleManager.ps1 -Modules $Modules -CompatibleVersion $Version 

    }
    
}

# EndRegion


# CSV Manager

function UserSearchString {
    param (
        $UserName
    )

    process {

        if ($UserName.Contains("@")) {
            return $UserName.Substring(0, $UserName.IndexOf("@"))
        }
    }
    
}

function SearchUsers {
    param (
        $UsersToSearchFromCsv,
        $UsersFromExchange,
        $UsersFromAzureAd
    )
    
    process {

        $FoundUsers = New-Object -TypeName "System.Collections.ArrayList"
        $NotFoundUsers = New-Object -TypeName "System.Collections.ArrayList"


        Write-Warning("Ricerca utenti in corso, questa operazione potrebbe richiedere diversi minuti... Attendere.")

        foreach ($userToSearch in $UsersToSearchFromCsv) {

            $UserNick = UserSearchString -UserName $userToSearch.Email
            # $UserNick = $userToSearch.Email
            

            $foundResultAAD = $UsersFromAzureAd | Where-Object { $_.ProxyAddresses -match $UserNick }
            
            if ($null -eq $foundResultAAD) {

                $foundResultExchange = $UsersFromExchange | Where-Object { $_.EmailAddresses -match $UserNick }

                if ($null -eq $foundResultExchange) {
                    $NotFoundUsers.Add($userToSearch)                    
                }
                else {
                    if ($null -ne $foundResultExchange.PrimarySmtpAddress) {
                        $result = @{
                            DisplayName        = $foundResultExchange.DisplayName
                            PrimarySmtpAddress = $foundResultExchange.PrimarySmtpAddress
                            EmailAddresses     = $foundResultExchange.EmailAddresses
                            LabName            = $userToSearch.LabName
                            Source             = "Exchange Online"
                        }
                        # Write-Host($result.Values)
                        # Write-Host($result.Get_Item("DisplayName"))
        
                        $FoundUsers.Add($result)
                    }
                }
            }
            else {

                try {
                
                    if ($null -ne $foundResultAAD.UserPrincipalName) {
                        $result = @{
                            DisplayName        = $foundResultAAD.DisplayName
                            PrimarySmtpAddress = $foundResultAAD.UserPrincipalName
                            EmailAddresses     = $foundResultAAD.ProxyAddresses
                            LabName            = $userToSearch.LabName
                            Source             = "Azure Active Directory"
                        }
                        # Write-Host($result.Values)
                        # Write-Host($result.Get_Item("DisplayName"))
        
                        $FoundUsers.Add($result)
                    }
                }
                catch {
                    
                }

            }

            Write-Host("Utenti processati $($FoundUsers.Count) di $($UsersToSearchFromCsv.Count)")

        }

        # $FoundUsers | Format-List -Property DisplayName,PrimarySmtpAddress
        # $FoundUsers | Format-Table

        Write-Host("Utenti trovati $($FoundUsers.Count) su $($UsersToSearchFromCsv.Count)")

        ExportResults -SuccessUsers $FoundUsers -ErrorUsers $NotFoundUsers

        return $FoundUsers

    }
}

function Get-UsersToSearch {
    param (
        $UsersFromCsv,
        $UsersFromExchange,
        $UsersFromAAD
    )
    
    process {

        return SearchUsers -UsersToSearch $UsersFromCsv -UsersFromExchange $UsersFromExchange -UsersFromAzureAd $UsersFromAAD
        
        # $FoundUsers = SearchUsers -UsersToSearch $UsersFromCsv -UsersFromExchange $UsersFromExchange -UsersFromAzureAd $UsersFromAAD

        # return MatchUsers -FoundUsers $FoundUsers
        # return $FoundUsers

    }
    
}

# .Des > verifica che le istanze del csv siano conformi
function VerifyCsv {
    param (
        $CsvUsers
    )

    process {
        try {
            ForEach ($CsvUser in $CsvUsers) {
                if ( [string]::IsNullOrEmpty($CsvUser.Email) -or [string]::IsNullOrWhiteSpace($CsvUser.Email) ) {
                    Write-Error("Il CSV non e' formattato correttamente, verificare il campo 'Email' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
                    exit
                }

                if ($null -eq $LabName) {
                    if ( [string]::IsNullOrEmpty($CsvUser.LabName) -or [string]::IsNullOrWhiteSpace($CsvUser.LabName) ) {
                        Write-Error("Il CSV non e' formattato correttamente, verificare il campo 'LabName' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
                        exit
                    }    
                }
                
            }

        }
        catch {
            Write-Error("Impossibile verificare il CSV, verificare che i campi siano conformi")
            exit
        }
    }
}

function CheckInputCsv {

    param (      
        [parameter()]
        [String]
        $Delimiter,

        [parameter(Mandatory = $true)]
        [String]
        $PathCSV
    )

    process {

        if ([string]::IsNullOrEmpty($Delimiter) -or [string]::IsNullOrWhiteSpace($Delimiter)) {
            $Delimiter = ','
        }

        if (',' -eq $Delimiter) {
            Write-Host("Si sta utilizzando il delimitatore di default, in quanto non fornito -> $($Delimiter)")
        } else {
            Write-Host("Delimitatore attualmente in uso -> $($Delimiter)")
        }
        
        if ([string]::IsNullOrEmpty($PathCSV) -or [string]::IsNullOrWhiteSpace($PathCSV)) {
            Write-Error("Il parametro PathCSV non pu� essere vuoto")
            exit
        }
        
        return $Delimiter
    }
    
}

function ProcessCsv {

    param (
        $PathCsv,
        $Delimiter
    )
    process {

        try {
            
            Write-Warning("Verifica del CSV in corso...")
            
            $delimiter = CheckInputCsv -Delimiter $Delimiter -PathCSV $PathCsv
            
            $CsvUsers = Import-Csv -Path $PathCSV -Delimiter $delimiter

            VerifyCsv -CsvUsers $CsvUsers

            return $CsvUsers
        
        }
        catch {
            Write-Error("Impossibile accedere al CSV, verificare il path e i campi")
            exit
        }
    }
}

#EndRegion

function ExitSessions {

    process {
        Write-Host("Disconnessione in corso...")
        Disconnect-ExchangeOnline -Confirm:$false | Out-Null
        Disconnect-AzAccount -Confirm:$false  | Out-Null
        Disconnect-AzureAD -Confirm:$false | Out-Null
        Clear-AzContext -Confirm:$false -Force | Out-Null
        Get-PSSession | Disconnect-PSSession -Confirm:$false | Out-Null
    }
    
}

function Get-DataFromAAD {
    param (
    )
    process {

        Write-Host("Ottenimento utenti da Azure Active Directory in corso... Attendere.")

        return Get-AzureADUser -All $true | Where-Object { $_.UserType -ne "Guest" }

    }
}

function Get-DataFromExchange {

    param (

    )

    process {

        Write-Host("Ottenimento utenti da Exchange Online in corso... Attendere.")
        return Get-Mailbox -Identity * -ResultSize Unlimited | Select-Object DisplayName, PrimarySmtpAddress, EmailAddresses

    }
    
}

function AddStudentsToLab {
    param (
        $UsersToInvite,
        $SendInvitation,
        $WelcomeMessaege
    )

    process {
        $LabsList = New-Object -TypeName "System.Collections.ArrayList"

        $UsersToInvite | ForEach-Object {

            try {
                # Write-Host($result.Values)
                # Write-Host($result.Get_Item("DisplayName"))

                $labName = $_.Get_Item("LabName")
                $userEmail = $_.Get_Item("PrimarySmtpAddress")

                if (($null -ne $labName) -and ($null -ne $userEmail)) {
                    

                    do {
                        $Lab = Get-AzLabAccount | Get-AzLab -LabName $labName

                        if($null -eq $Lab){
                            Write-Warning("Nella sottoscrizione corrente non sono stati trovati Lab Account di Azure Lab Services.")
                            $sub = Get-AzSubscription
                            Write-Host("Nome sottoscrizione corrente -> $($subName)")
                            Write-Host("Id sottoscrizione corrente -> $($sub.Id)")

                            do {
                                Write-Host("Inserire il nome o l'ID della sottoscrizione in cui si trova il Lab Account di Azure Lab Services.")
                                $labName = Read-Host("->  ")

                            } while ([string]::IsNullOrEmpty($labName) -or [string]::IsNullOrWhiteSpace($labName))

                        }

                    } while ($null -eq $Lab)

                    Add-AzLabUser -Lab $Lab -Emails $userEmail
                    Write-Warning("*** Aggiunta al laboratorio $($labName) di $($userEmail) completata ***")

                    $LabsList.Add($labName)
                }
            }
            catch {
                
            }
            
        }

            
        if ([string]::IsNullOrEmpty($SendInvitation) -or [string]::IsNullOrWhiteSpace($SendInvitation)) {
            Write-Warning("Non e' stato abilitato l'invito automatico degli utenti. Sar� necessario recarsi su https://labs.azure.com e invitarli facendo click sul bottone 'Invita tutti'")
           
        }
        else {
            $Labs = $LabsList | Get-Unique

            if ([string]::IsNullOrEmpty($WelcomeMessaege) -or [string]::IsNullOrWhiteSpace($WelcomeMessaege)) {
                $WelcomeMessaege = "Benenuto su Azure LabServices"
            }

            foreach ($Lab in $Labs) {
                $CurrentLab = Get-AzLabAccount | Get-AzLab -LabName $Lab

                $LabUsers = Get-AzLabUser -Lab $CurrentLab

                foreach ($User in $LabUsers) {
                    Send-AzLabUserInvitationEmail -User $User -InvitationText $WelcomeMessaege -Lab $CurrentLab
                    Write-Warning("*** Invito al laboratorio $($CurrentLab.name) inviato a $($User.properties.email) ***")
                }
    
            }
        }
        
    }
    
}

function ExportResults {
    param (
        $ErrorUsers,
        $SuccessUsers
    )

    process {
        $dateTime = Get-Date -Format "MMMM-dd-yyyy"

        $FileNameError = ".\Error_" + "$($dateTime)" + ".txt"
        $FileNameSuccess = ".\Success_" + "$($dateTime)" + ".txt"

        $ErrorUsers | Out-File $FileNameError

        $SuccessUsers | Out-File $FileNameSuccess

    }
}

# BODY

PrepareEnvironment -Modules "ExchangeOnlineManagement", "AzureAD", "Az", "Az.LabServices" -Version 5

Connect-ExchangeOnline | Out-Null

Connect-AzureAD

if ([string]::IsNullOrEmpty($AzureSub) -or [string]::IsNullOrWhiteSpace($AzureSub)) {
    Write-Warning("Si utilizzerà la sottoscrizione predefinita, non è stato fornita una sottoscrizione.")
    Connect-AzAccount
}
else {
    Connect-AzAccount -Subscription $AzureSub
}

$UsersFromCsv = ProcessCsv -PathCSV $PathCsv -Delimiter $Delimiter

# $UsersFromCsv

Write-Warning("Ricerca utenti in corso, l'operazione potrebbe richiedere alcuni minuti. Attendere...")

$ExchangeUsers = Get-DataFromExchange
$AadUsers = Get-DataFromAAD

$FoundUsers = Get-UsersToSearch -UsersFromCsv $UsersFromCsv -UsersFromExchange $ExchangeUsers -UsersFromAAD $AadUsers

AddStudentsToLab -UsersToInvite $FoundUsers

ExitSessions

Write-Host("***Esecuzione script completata ***")
