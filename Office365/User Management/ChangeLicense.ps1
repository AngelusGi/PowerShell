#Rev3


Param
(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]
    $PathCSV,

    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]
    $AzureSubId,

    [parameter(ValueFromPipeline = $true)]
    [String]
    $Delimiter,

    [parameter(ValueFromPipeline = $true)]
    [SecureString]
    $VmPassword    
)


if ([string]::IsNullOrEmpty($Delimiter) -or [string]::IsNullOrWhiteSpace($Delimiter)) {
    $Delimiter = ";"
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
    break
}
elseif ([string]::IsNullOrEmpty($PathCSV) -or [string]::IsNullOrWhiteSpace($PathCSV)) {
    Write-Error("Il parametro PathCSV non può essere vuoto")
    break
}
elseif ([string]::IsNullOrEmpty($AzureSubId) -or [string]::IsNullOrWhiteSpace($AzureSubId)) {
    Write-Error("Il parametro AzureSubId non può essere vuoto")
    break
}
else {
    Write-host("Parametri:")
    Write-host("Path CSV: $($PathCSV)")
    Write-host("Delimitatore del file CSV: $($Delimiter)")
    Write-host("Subscription di Azure: $($AzureSubId)")
    Write-host("Messaggio d'invito: $($InvitationText)")
    Write-Host("***")
}



Install-Module MSOnline

$OldLicense = "OLD LICENSE SKU"
$NewLicense = "NEW LICENSE SKU"
$UserToChangeLicense = "docente"


Connect-MsolService -Credential $AdminCred

$Users = Get-MsolUser
    
foreach ($User in $Users){

    if ($User.Title -eq  $UserToChangeLicense) {
        $Upn = $User.UserPrincipalName
        Write-Host("")

        Write-Host("Modifica in corso su: '$($Upn)'")

        Set-MsolUserLicense -UserPrincipalName $Upn -AddLicenses $NewLicense -RemoveLicenses $OldLicense

        Write-Host("")
        # Write-Host("Modifica terminata su: '$($Upn)'"
    }
    

}

Write-Host(" *** OPERAZIONE COMPLETATA *** ")
