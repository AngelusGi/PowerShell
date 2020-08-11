# PARAMETRI DA MODIFICARE #

$teamNameA = "Test Teams CSV 1" #Modificare insierendo il nome del team (lo stesso prensente anche nel CSV
$teamNameB = "Test Teams CSV 2" #Modificare insierendo il nome del team (lo stesso prensente anche nel CSV

$PathCSV = ".\csv_test.CSV" #Modificare inserendo la path e il nome del file CSV che contiene gli utenti da inserire

# FINE PARAMETRI DA MODIFICARE #

Install-Module MicrosoftTeams -Force -Verbose

Connect-MicrosoftTeams

$teamA = Get-Team -DisplayName $teamNameA
$teamB = Get-Team -DisplayName $teamNameB

try {
    if ( ($null -eq $teamA) -or ($null -eq $teamB) ) {
        Write-Error("*** NON TUTTI I TEAM ESISTONO ***")
        Write-Warning("*** CREARE PRIMA ENTRAMBI I TEAM ***")

    } else {
        Write-Warning("*** I TEAM EISTONO, CARICAMENTO UTENTI IN CORSO... ***")
    
        $guestUsers = Import-Csv $PathCSV -Delimiter ';'

        $guestUsers | ForEach-Object {

            $email = $_.Email

            if ($_.Team.Equals($teamA.DisplayName)) {
                # $group = Get-Team -MailNickName $teamNameA
                
                Add-TeamUser -GroupId $teamA.GroupId -User $email
                Write-Warning("*** Operazione compeltata su '" + $email + "' nel team '" + $teamA.DisplayName + "' ***")
            
            } elseif ($_.Team.Equals($teamB.DisplayName)) {
                # $group = Get-Team -MailNickName $teamNameB

                Add-TeamUser -GroupId $teamB.GroupId -User $email
                Write-Warning("*** Operazione compeltata su '" + $email + "' nel team '" + $teamB.DisplayName + "' ***")
            
            } else {
                Write-Error("Errore, nessun team riconosciuto. Il nome team del CSV non � un nome valido.")
            }

            Write-Host("")
            Write-Host("")
        }
    }
}
catch {
    Write-Error("*** I TEAM NON EISTONO ***")
    break
}
