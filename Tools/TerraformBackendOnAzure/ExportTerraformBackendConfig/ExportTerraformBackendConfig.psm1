
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

        if ([string]::IsNullOrEmpty($MainFilePath) -or [string]::IsNullOrWhiteSpace($MainFilePath) ) {
            $currentPath = Get-Location
        }

        if ([string]::IsNullOrEmpty($OutputFilePath) -or [string]::IsNullOrWhiteSpace($OutputFilePath) ) {
            $currentPath = Get-Location
            $outputFolder = "Output"
            New-Item -Path $currentPath -ItemType Directory -Value $outputFolder

            $OutputFilePath = Join-Path -Path $currentPath -ChildPath $outputFolder -Resolve -ErrorAction Stop
        }

        try {
            $terraformFileOutput = Join-Path -Path $OutputFilePath -ChildPath "$($MainTerraformFileName).tf" -Resolve
        }
        catch {
            $OutputFilePath = Join-Path -Path $OutputFilePath -ChildPath "$($MainTerraformFileName).tf"
            $terraformFileOutput = New-Item -Path $OutputFilePath -ItemType File
        }

        # Adds terraform snippet to the main file
        Add-Content -Path $terraformFileOutput -Value $TerraformSnippet

        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Il seguente snippet per configurare il backend di Terraform è stato salvato nel file $($MainTerraformFileName) al seguente percorso"
        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "$($customerPath)$($terraformFileOutput)"
        $TerraformSnippet
    }
    
}


Export-ModuleMember -Function Set-TerraformFolder
