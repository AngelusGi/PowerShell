<# TEST PURPOSE

$userName = 
$userPassword = 

$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force

$cred = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#>

# PARAMETERS DESCRIPTION #

# $PathCSV ex. ".\AddStudents_SendInvitation.CSV" # Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire
# $Delimiter ex. ',' # Delimitatore del file CSV - valore di default ";"
# $VmPassword # ex. "Contoso1234@" # Password dell'utente locale della macchina virtuale
# $AzureSub # ex. "1234-abcd-5678-xxxx-00yyyy" or "My Subscription" # Azure Subscription Id or Name # Per ottenerlo, usare il comando Connect-AzAccount -> Get-AzSubscription

# END PARAMETERS #

Param
(
    [parameter(Mandatory = $true)]
    [String]
    $PathCSV,

    [parameter(Mandatory = $true)]
    [String]
    $AzureSub,

    [parameter()]
    [String]
    $Delimiter = ",",

    [parameter()]
    [SecureString]
    $VmPassword
)


function Set-PsEvnironment {
    param(
        [Parameter(
            HelpMessage = "Modules name to install from the GitHub tool repo.",
            Mandatory = $false)]
        [ValidateSet("ModuleManager", "TerraformBackendOnAzure")]
        [string[]]
        $ModulesToInstall = "ModuleManager"
    )

    process {
        $psModuleExtension = "psm1"
    
        foreach ($module in $ModulesToInstall) {

            $libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/$($module)/$($module).$($psModuleExtension)"
            $module = "$($module).$($psModuleExtension)"

            $client = New-Object System.Net.WebClient
            $currentPath = Get-Location
            $downloadPath = Join-Path -Path $currentPath.Path -ChildPath $module
            $client.DownloadFile($libraryUrl, $downloadPath)
            
            $modToImport = Join-Path -Path $currentPath.Path -ChildPath $module -Resolve -ErrorAction Stop
            Import-Module $modToImport -Verbose
            Remove-Item -Path $modToImport -Force
        }
    }

}


if ([string]::IsNullOrEmpty($VmPassword) -or [string]::IsNullOrWhiteSpace($VmPassword)) {
    $InvitationText = "Contatta l'amministratore per avere informazioni circa la password."

}
else {
    $SecurePassword = $VmPassword | ConvertTo-SecureString -AsPlainText -Force
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $InvitationText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}


if ([string]::IsNullOrWhiteSpace($Delimiter)) {
    Write-Error("Il parametro Delimiter non può essere vuoto")
    exit
}
elseif ([string]::IsNullOrEmpty($PathCSV) -or [string]::IsNullOrWhiteSpace($PathCSV)) {
    Write-Error("Il parametro PathCSV non può essere vuoto")
    exit
}
elseif ([string]::IsNullOrEmpty($AzureSub) -or [string]::IsNullOrWhiteSpace($AzureSub)) {
    Write-Error("Il parametro AzureSub non può essere vuoto")
    exit
}
else {
    Write-Host("Parametri:")
    Write-Host("Path CSV: $($PathCSV)")
    Write-Host("Delimitatore del file CSV: $($Delimiter)")
    Write-Host("Subscription di Azure: $($AzureSub)")
    Write-Host("Messaggio d'invito: $($InvitationText)")
    Write-Host("***")
}


try {

    Write-Warning("Verifica del CSV in corso...")
    $Users = Import-Csv $PathCSV -Delimiter $Delimiter

    ForEach ($email in $Users.Email) {
        if ( [string]::IsNullOrEmpty($email) -or [string]::IsNullOrWhiteSpace($email) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'Email' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }
    }

    ForEach ($labName in $Users.LabName) {
        if ( [string]::IsNullOrEmpty($labName) -or [string]::IsNullOrWhiteSpace($labName) ) {
            Write-Error("Il CSV non è formattato correttamente, verificare il campo 'LabName' e verificare che non sia vuoto o che sia avvalorato su tutte le istanze")
            exit
        }
    }


}
catch {
    Write-Error("Impossibile accedere al CSV, verificare il path e i campi")
    exit
}

function AzureConnect {
    process {
        if ([System.Environment]::OSVersion.Platform -ne "Win32NT") {
            Connect-AzAccount -SubscriptionId $AzureSub -UseDeviceAuthentication
        }
        else {
            Connect-AzAccount -SubscriptionId $AzureSub
        }
    }
    
}

Set-PsEvnironment -PsModulesToInstall  "Az", "Az.LabServices"

AzureConnect

$Users | ForEach-Object {

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
