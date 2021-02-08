<# TEST PURPOSE

$userName = 
$userPassword = 

$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force

$cred = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#>

Param
(
    [parameter(Mandatory = $true)]
    [String]
    $PathCSV,

    [parameter()]
    [String]
    $AzureSubId,

    [parameter()]
    [String]
    $Delimiter = ',',

    [parameter()]
    [string]
    $SendInvitation,

    [parameter()]
    [String]
    $WelcomeMessaege
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
    
        $Client.DownloadFile($LibraryURL, "ModuleManager.ps1")

        .\ModuleManager.ps1 -Modules $Modules -CompatibleVersion $Version 

    }
    
}

# EndRegion


# CSV Manager

function SearchUsers {
    param (
        $UsersToSearchFromCsv,
        $UsersFromExchange
    )
    
    process {

        $FoundUsers = New-Object -TypeName "System.Collections.ArrayList"
        $NotFoundUsers = New-Object -TypeName "System.Collections.ArrayList"


        Write-Warning("Ricerca utenti in corso... Attendere.")

        foreach ($userToSearch in $UsersToSearchFromCsv) {
            $foundResult = $UsersFromExchange | Where-Object { $_.EmailAddresses -match $userToSearch.Email }
            
            
            if ($null -eq $foundResult) {
                $NotFoundUsers.Add($userToSearch)
            }
            else {

                try {
                
                    if ($null -ne $foundResult.PrimarySmtpAddress) {
                        $result = @{
                            DisplayName        = $foundResult.DisplayName
                            PrimarySmtpAddress = $foundResult.PrimarySmtpAddress
                            EmailAddresses     = $foundResult.EmailAddresses
                            LabName            = $userToSearch.LabName
                        }
        
                        # Write-Output($result.Values)
                        # Write-Output($result.Get_Item("DisplayName"))
        
                        $FoundUsers.Add($result)
                    }
                }
                catch {
                    
                }

            }

            Write-Output("Utenti processati $($FoundUsers.Count) di $($UsersToSearchFromCsv.Count)")

        }

        # $FoundUsers | Format-List -Property DisplayName,PrimarySmtpAddress
        # $FoundUsers | Format-Table

        Write-Output("Utenti trovati $($FoundUsers.Count) su $($UsersToSearchFromCsv.Count)")

        ExportResults -SuccessUsers $FoundUsers -ErrorUsers $NotFoundUsers

        return $FoundUsers

    }
}

function Get-UsersToSearch {
    param (
        $PathCsv,
        $UsersFromExchange
    )
    
    process {

        $UsersFromCsv = ProcessCsv -PathCSV $PathCsv
        
        $FoundUsers = SearchUsers -UsersToSearch $UsersFromCsv -UsersFromExchange $UsersFromExchange

        # return MatchUsers -FoundUsers $FoundUsers
        return $FoundUsers

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
                    Write-Error("Il CSV non è formattato correttamente, verificare il campo 'Email' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
                    exit
                }

                if ( [string]::IsNullOrEmpty($CsvUser.LabName) -or [string]::IsNullOrWhiteSpace($CsvUser.LabName) ) {
                    Write-Error("Il CSV non è formattato correttamente, verificare il campo 'LabName' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
                    exit
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

        if (',' -eq $Delimiter) {
            Write-Warning("Si sta utilizzando il delimitatore di default, in quanto non fornito: $($Delimiter)")
        }
        
        if ([string]::IsNullOrEmpty($PathCSV) -or [string]::IsNullOrWhiteSpace($PathCSV)) {
            Write-Error("Il parametro PathCSV non può essere vuoto")
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
        Disconnect-ExchangeOnline -Confirm:$false
        Disconnect-AzAccount -Confirm:$false
        Get-PSSession | Disconnect-PSSession -Confirm:$false
    }
    
}

function Get-DataFromExchange {

    param (

    )

    process {

        Write-Warning("Ottenimento utenti da Exchange Online in corso... Attendere.")
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
                # Write-Output($result.Values)
                # Write-Output($result.Get_Item("DisplayName"))

                $labName = $_.Get_Item("LabName")
                $userEmail = $_.Get_Item("PrimarySmtpAddress")
            
                if (($null -ne $labName) -and ($null -ne $userEmail)) {
                    $Lab = Get-AzLabAccount | Get-AzLab -LabName $labName

                    Add-AzLabUser  -Lab $Lab -Emails $userEmail
                    Write-Warning("*** Aggiunta al laboratorio $($labName) di $($userEmail) completata ***")

                    $LabsList.Add($labName)
                }
            }
            catch {
                
            }
            
        }

            
        if ([string]::IsNullOrEmpty($SendInvitation) -or [string]::IsNullOrWhiteSpace($SendInvitation)) {
            Write-Warning("Non è stato abilitato l'invito automatico degli utenti. Sarà necessario recarsi su https://labs.azure.com e invitarli facendo click sul bottone 'Invita tutti'")
           
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

PrepareEnvironment -Modules "ExchangeOnlineManagement", "Az", "Az.LabServices"

$cred = Get-Credential

Connect-ExchangeOnline -Credential $cred

$UserAlias = Get-DataFromExchange

$FoundUsers = Get-UsersToSearch -PathCsv $PathCSV -UsersFromExchange $UserAlias

Connect-AzAccount -Credential $cred

AddStudentsToLab -UsersToInvite $FoundUsers

ExitSessions

Write-Output("***Esecuzione script completata ***")
