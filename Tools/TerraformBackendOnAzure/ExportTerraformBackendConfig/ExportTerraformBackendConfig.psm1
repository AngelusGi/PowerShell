
function Set-TerraformFolder {
    param (
        # Parameter main.tf file path as output
        [Parameter(
            HelpMessage = "Path where will be saved the output Main.tf within the backend configuration. Default: script execution folder.",
            Mandatory = $false
        )]
        [string]
        $OutputFilePath,
        
        # Parameter main.tf file path as input
        [Parameter(
            HelpMessage = "Path from wich will be imported the output Main.tf without the backend configuration. Default: script execution folder.",
            Mandatory = $false
        )]
        [string]
        $MainFilePath,

        # Name of the terraform main file
        [Parameter(
            HelpMessage = "Name of the main Terraform file (no extension required). Default: main",
            Mandatory = $false
        )]
        [string]
        $MainTerraformFileName = 'main',

        [Parameter(
            HelpMessage = "Snippet to add to the terraform main file",
            Mandatory = $true
        )]
        [string]
        $TerraformSnippet
    )

    process {
        Export-Terraform -MainTerraformFileName $MainTerraformFileName -TerraformSnippet $TerraformSnippet -OutputFilePath $OutputFilePath -MainFilePath $MainFilePath

    }

}

# Accountable of the exporting all terraform related operations
function Export-Terraform {
    [CmdletBinding()]
    param (
        # Parameter main.tf file path as output
        [Parameter(
            HelpMessage = "Path where will be saved the output Main.tf within the backend configuration. Default: script execution folder.",
            Mandatory = $false
        )]
        [string]
        $OutputFilePath,
        
        # Parameter main.tf file path as input
        [Parameter(
            HelpMessage = "Path from wich will be imported the output Main.tf without the backend configuration. Default: script execution folder.",
            Mandatory = $false
        )]
        [string]
        $MainFilePath,

        # Name of the terraform main file
        [Parameter(
            HelpMessage = "Name of the main Terraform file (no extension required). Default: main",
            Mandatory = $false
        )]
        [string]
        $MainTerraformFileName = 'main',

        [Parameter(
            HelpMessage = "Snippet to add to the terraform main file",
            Mandatory = $true
        )]
        [string]
        $TerraformSnippet
    )
    
    process {

        $mainTfName = "$($MainTerraformFileName).tf"

        if ([string]::IsNullOrEmpty($MainFilePath) -or [string]::IsNullOrWhiteSpace($MainFilePath) ) {
            $currentPath = (Get-Location).Path
        }

        if ([string]::IsNullOrEmpty($OutputFilePath) -or [string]::IsNullOrWhiteSpace($OutputFilePath) ) {
            $currentPath = (Get-Location).Path
            $outputFolder = "Output"
            
            try {
                New-Item -Path $currentPath -ItemType Directory -Name $outputFolder -Force
            }
            catch {
                Write-Error "Verificare che la cartella $($outputFolder) non sia bloccata"
            }

            $OutputFilePath = Join-Path -Path $currentPath -ChildPath $outputFolder -Resolve -ErrorAction Stop
        }

        try {
            $terraformFileOutput = New-Item -Path $OutputFilePath -Name $mainTfName -Force -ItemType File
        }
        catch {
            Write-Error "Verificare che il file e la cartella $($terraformFileOutput) non siano bloccatai"
        }

        # Adds terraform snippet to the main file
        Add-Content -Path $terraformFileOutput -Value $TerraformSnippet

        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Il seguente snippet per configurare il backend di Terraform è stato salvato nel file $($MainTerraformFileName) al seguente percorso"
        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "$($terraformFileOutput)"
        $TerraformSnippet
    }
    
}


Export-ModuleMember -Function Set-TerraformFolder
