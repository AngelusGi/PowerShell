<# TEST PURPOSE #

$userName = 
$userPassword = 

$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force

$cred = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#>

# Param
# (
#     [parameter(Mandatory = $true, ValueFromPipeline = $true)]
#     [String]
#     $PathCSV,

#     [parameter(Mandatory = $true, ValueFromPipeline = $true)]
#     [String]
#     $AzureSubId,

#     [parameter(ValueFromPipeline = $true)]
#     [String]
#     $Delimiter
# )

$PathCSV = ".\Azure\Lab Services\Add students by alias\csv_test.CSV"

# Region module manager

function CheckModules {
    param (
        $Modules,
        [String]$Scope
    )
    process {

        if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
            Write-Error -Message ('Il modulo AzureRM è installato sulla macchina. Rimuoverlo prima di procedere.')
            Break
        }

        $installedModules = Get-InstalledModule

        foreach ($module in $Modules) {
            
            $GalleryModule = Find-Module -Name $module

            $mod = $installedModules | Where-Object { $_.Name -eq $module }
        
            if ([string]::IsNullOrEmpty($mod) -or [string]::IsNullOrWhiteSpace($mod)) {
                Write-Warning("Modulo $($module) non trovato. Installazione in corso...")
                Install-Module -Name $module -Scope $Scope -AllowClobber
            }
            else {
                Write-Warning("Modulo $($module) trovato.")

                if ($GalleryModule.Version -ne $mod.Version) {
                    Write-Warning("Aggionamento del modulo $($module) in corso...")

                    Update-Module -Name $module
                }
            }
        }

        Write-Warning("Installazione del modulo Az.LabServices in corso...")

        $LabServiceLibraryURL = "https://raw.githubusercontent.com/Azure/azure-devtestlab/master/samples/ClassroomLabs/Modules/Library/Az.LabServices.psm1"

        $Client = New-Object System.Net.WebClient

        $Client.DownloadFile($LabServiceLibraryURL, ".\Az.LabServices.psm1")

        Import-Module .\Az.LabServices.psm1
        
    }
}

function VerifyPsVersion {
    
    process {
        
        Write-Warning("Verifica dell'ambiente in corso, attendere...")

        if ($PSVersionTable.PSVersion.Major -ne 5) {
            Write-Error("Questo script può essere eseguito solo con la versione 5 di Windows PowerShell")
            exit
        }
    }
}

function InstallLocalModules {
    param (
        [String]$Scope
    )

    process {

        VerifyPsVersion

        $Modules = "AzureAd", "MSOnline", "ExchangeOnlineManagement", "Az"

        CheckModules -Modules $Modules -Scope $Scope
        
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

        Write-Warning("Ricerca utenti in corso... Attendere.")

        foreach ($userToSearch in $UsersToSearchFromCsv) {
            $found = $UsersFromExchange | Where-Object { $_.EmailAddresses -match $userToSearch }

            $FoundUsers.Add($found)
        }

        # $FoundUsers | Format-List -Property DisplayName,PrimarySmtpAddress
        # $FoundUsers | Format-Table


        Write-Output("Utenti trovati $($FoundUsers.Count) su $($UsersToSearchFromCsv.Count)")

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

        return MatchUsers -FoundUsers $FoundUsers

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
        [parameter(ValueFromPipeline = $true)]
        [String]
        $Delimiter,

        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $PathCSV
    )

    process {

        if ([string]::IsNullOrEmpty($Delimiter) -or [string]::IsNullOrWhiteSpace($Delimiter)) {
            $Delimiter = ';'
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
        Disconnect-AzureAD -Confirm:$false
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

function MatchUsers {

    param(
        $FoundUsers,
        $DomainName
    )

    process {

        $SuccessUsers = New-Object -TypeName "System.Collections.ArrayList"
        $ErrorUsers = New-Object -TypeName "System.Collections.ArrayList"
        
        foreach ($found in $FoundUsers) {
            foreach ($item in $found) {
        
                $currentUser = $null

                try {
                    $search = $item.Identity + $DomainName
                    Write-Warning("$($search)")
                    $currentUser = Get-MsolUser -UserPrincipalName $search

                    if ($null -eq $currentUser) {
                        $dateTime = Get-Date
                        $ErrorUsers.Add(
                            "-----
                    $($dateTime)
                    *****
                    $($item)
                    *****
                    $($search)
                    -----")

                        Write-Warning("Errore, verfificare il log.")

                    }
                    else {
                        $currentUser | Format-List UserPrincipalName, SignInName, DisplayName, ObjectId, UserType, ValidationStatus
                        $SuccessUsers.Add($currentUser)
                
                    }
                    # $currentUser =  Get-AzureADUser -SearchString $search  | Format-List UserPrincipalName, SignInName, DisplayName, ObjectId, ObjectType, AccountEnabled
                    Write-Output("")
                }
                catch [Microsoft.Online.Administration.Automation.MicrosoftOnlineException], [Microsoft.Online.Administration.Automation.GetUser] {
                    $dateTime = Get-Date
                    
                    $ErrorUsers.Add(
                        "$($dateTime)
                        $($item)
                        $($_.Exception.Message)")

                    Write-Error("Errore, verfificare il log.")
                }
        
            }
        }

        return $SuccessUsers
    }
}


function AddStudentsToLab {
    param (
        $UsersToInvite,
        $CsvUsers
    )

    process {

        $UsersToInvite | ForEach-Object {

            $Lab = Get-AzLabAccount | Get-AzLab -LabName $_.LabName

            Add-AzLabUser  -Lab $Lab -Emails $_.Email
            Write-Warning("*** Aggiunta al laboratorio $($_.LabName) di $($_.Email) completata ***")

        }

        $Labs = $Users.LabName | Get-Unique

        foreach ($Lab in $Labs) {
            $CurrentLab = Get-AzLabAccount | Get-AzLab -LabName $Lab

            $LabUsers = Get-AzLabUser -Lab $CurrentLab

            foreach ($User in $LabUsers) {
                Send-AzLabUserInvitationEmail -User $User -InvitationText $InvitationText -Lab $CurrentLab
                Write-Warning("*** Invito al laboratorio $($CurrentLab.name) inviato a $($User.properties.email) ***")
            }
    
        }
    }
    
}

# BODY

InstallLocalModules -Scope CurrentUser

# $cred = Get-Credential

Connect-ExchangeOnline -Credential $cred

$UserAlias = Get-DataFromExchange

$FoundUsers = Get-UsersToSearch -PathCsv $PathCSV -UsersFromExchange $UserAlias


# TODO IMPLEMENTARE FUNZIONE PER ESPORTARE ELENCO UTENTI NON TROVATI


# Connect-AzureAD -Credential $cred

# Connect-MsolService -Credential $cred

# Connect-AzAccount -SubscriptionId $AzureSubId -Credential $Cred

# AddStudentsToLab -UsersToInvite $FoundUsers -CsvUsers $csv

# to do -> invite users

$dateTime = Get-Date -Format "MMMM-dd-yyyy"

$FileNameError = ".\Error_" + "$($dateTime)" + ".txt"
$FileNameSuccess = ".\Success_" + "$($dateTime)" + ".txt"

$ErrorUsers | Out-File $FileNameError

$SuccessUsers | Out-File $FileNameSuccess

ExitSessions
