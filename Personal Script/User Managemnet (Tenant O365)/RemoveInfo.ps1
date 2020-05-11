#Rev3

Install-Module Azure
Install-Module MSOnline

$AdUser = "ADMIN TENANT"
$AdPswd = ConvertTo-SecureString 'ADMIN PSWD' -AsPlainText -Force
$AdminCred = New-Object System.Management.Automation.PSCredential $AdUser, $AdPswd

try {

    Connect-MsolService -Credential $AdminCred

    $Users = Get-MsolUser

    $Empty = "-"
        
    foreach ($User in $Users){

        $Upn = $User.UserPrincipalName

        Write-Host "Modifica in corso su: '$($Upn)'"

        Set-MsolUser -UserPrincipalName $Upn -MobilePhone $Empty -Office $Empty -PhoneNumber $Empty -Fax $Empty

        Write-Host ""

    }

    Write-Host " *** OPERAZIONE COMPLETATA *** "
    
}
catch {
    Write-Host " *** ERRORE *** "
    
}

