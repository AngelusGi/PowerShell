#Rev3

$AdUser = "ADMIN TENANT"
$AdPswd = ConvertTo-SecureString 'ADMIN PSWD' -AsPlainText -Force
$AdminCred = New-Object System.Management.Automation.PSCredential $AdUser, $AdPswd

$OldLicense = "OLD LICENSE SKU"
$NewLicense = "NEW LICENSE SKU"
$UserToChangeLicense = "docente"


Connect-MsolService -Credential $AdminCred

$Users = Get-MsolUser
    
foreach ($User in $Users){

    if ($User.Title -eq  $UserToChangeLicense) {
        $Upn = $User.UserPrincipalName
        Write-Host ""

        Write-Host "Modifica in corso su: '$($Upn)'"

        Set-MsolUserLicense -UserPrincipalName $Upn -AddLicenses $NewLicense -RemoveLicenses $OldLicense

        Write-Host ""
        # Write-Host "Modifica terminata su: '$($Upn)'"
    }
    

}

Write-Host " *** OPERAZIONE COMPLETATA *** "
