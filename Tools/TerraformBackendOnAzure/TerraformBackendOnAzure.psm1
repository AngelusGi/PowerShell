#region custom functions

function Set-TerraformBackend {
    [CmdletBinding()]
    param (

        ### Other parametes ###

        # Resource name prefix
        [Parameter(
            HelpMessage = "Resource prefix (e.g. project name). Default: TfBackend.",
            Mandatory = $false
        )]
        [string]
        $ResourcePrefix = "TfBackend",
            
        # Parameter main.tf file path as input
        [Parameter(
            HelpMessage = "Path from wich will be imported the output Main.tf without the backend configuration. Default: script execution folder.",
            Mandatory = $false
        )]
        [string]
        $MainFilePath,

        # Parameter main.tf file path as output
        [Parameter(
            HelpMessage = "Path where will be saved the output Main.tf within the backend configuration. Default: script execution folder.",
            Mandatory = $false
        )]
        [string]
        $OutputFilePath,

        [Parameter(
            HelpMessage = "Max lenght of resource prefix. Default: 10",
            Mandatory = $false)]
        [int]
        $MaxLenght,

        [Parameter(
            HelpMessage = "Min lenght of resource prefix. Default: 4",
            Mandatory = $false)]
        [int]
        $MinLenght = 4,


        ### Azure common parametes ###
    
        # Azure Subscription Name or Id
        [Alias("AzureSubscriptionName", "AzureSubscriptionId", "AzureSubscription")]
        [Parameter(
            HelpMessage = "Azure Subscription Name or Id.",
            Mandatory = $false
        )]
        [string]
        $AzSub,
    
        # Azure region name
        [Parameter(
            HelpMessage = "Azure region name. Default: westeurope.",
            Mandatory = $false
        )]
        [string]
        $AzRegion = 'westeurope',
    
        # Azure Tag
        [Parameter(
            HelpMessage = "{
                app = 'TerraformBackend'
                iac = 'PowerShell'
                }",
            Mandatory = $false
        )]
        [hashtable]
        $AzTag = @{
            app = 'TerraformBackend'
            iac = 'PowerShell'
        },
    

        ### Azure resource group parametes ###
    
        # Resource Group Name
        [Alias("ResourceGroupName", "ResourceGroup")]
        [Parameter(
            HelpMessage = "Resource Group Name. Default name: TfBackend-rg",
            Mandatory = $false
        )]
        [string]
        $AzResGroup,


        ### Azure storage parametes ###
        
        # Stg Account name
        [Parameter(
            HelpMessage = "Storage Account Name. Automatically will be added the postfix 'stg'. Default name: tfbackend1234stg",
            Mandatory = $false
        )]
        [string]
        $AzStorageAccount,
    
        # SKU of the Azure Storage Account
        [Alias("StorageAccountSku")]
        [ValidateSet("Standard_LRS", "Premium_LRS", "Premium_ZRS", "Standard_GRS", "Standard_GZRS", "Standard_LRS", "Standard_RAGRS", "Standard_RAGZRS", "Standard_ZRS")]
        [Parameter(
            HelpMessage = "SKU of the Storage Account. Default: Standard_LRS",
            Mandatory = $false
        )]
        [string]
        $AzStgSku = 'Standard_LRS',
    
        # Stg Acc Container name
        [Parameter(
            HelpMessage = "Name of the container in the Storage Account. Default: terraformstate",
            Mandatory = $false
        )]
        [string]
        $TerraformContainer = 'terraformstate',
        
    
        ### Azure Key Vault parametes ###
    
        # Key Vault Name
        [Alias("KeyVault", "KeyVaultName")]
        [Parameter(
            HelpMessage = "Key Vault Name. Automatically will be added the postfix '-kv'. Default name: tfbackend1234-kv",
            Mandatory = $false)]
        [string]
        $AzKeyVault,
    
        # SKU of the Azure Key Vault
        [Alias("KeyVaulSku")]
        [ValidateSet("Standard", "Premium")]
        [Parameter(
            HelpMessage = "SKU of the Key Vault. Default: Standard",
            Mandatory = $false
        )]
        [string]
        $AzKvSku = 'Standard',


        ### Terraform parametes ###
    
        # Name of the terraform main file
        [Parameter(
            HelpMessage = "Name of the main Terraform file (no extension required). Default: main",
            Mandatory = $false
        )]
        [string]
        $MainTerraformFileName = 'main'
    )

    process {
        Set-Terraform -ModulesToInstall

        $terraformOutput = Set-TerraformBackend
            -MainFilePath $MainFilePath -OutputFilePath $OutputFilePath -MainTerraformFileName $MainTerraformFileName
            -ResourcePrefix $ResourcePrefix -AzSub $AzSub -AzRegion $AzRegion -AzTag $AzTag
            -AzStgSku $AzStgSku -AzResGroup $AzResGroup -AzStorageAccount $AzStorageAccount
            -TerraformContainer $TerraformContainer -AzKvSku $AzKvSku -AzKeyVault $AzKeyVault

            Set-TerraformFolder -MainTerraformFileName $MainTerraformFileName -TerraformSnippet $terraformOutput -OutputFilePath $OutputFilePath -MainFilePath $MainFilePath

    }

    #region module manager

    #endregion
}

function Set-Terraform {
    param(
        [Parameter(
            HelpMessage = "Modules name to install from the GitHub tool repo.",
            Mandatory = $true)]
        [ValidateSet("ConfigureTerraformBackend", "ExportTerraformBackendConfig")]
        [string[]]
        $ModulesToInstall
    )

    process {
        $psModuleExtension = "psm1"
    
        foreach ($module in $ModulesToInstall) {

            $libraryUrl = "https://raw.githubusercontent.com/AngelusGi/PowerShell/master/Tools/TerraformBackendOnAzure/$($module)/$($module).$($psModuleExtension)"

            $module = "$($module).$($psModuleExtension)"

            $client = New-Object System.Net.WebClient
            $currentPath = Get-Location
            $downloadPath = Join-Path -Path $currentPath.Path -ChildPath $module
            $client.DownloadFile($libraryUrl, $downloadPath)
            
            $modToImport = Join-Path -Path $currentPath.Path -ChildPath $module -Resolve -ErrorAction Stop
            Import-Module $modToImport
            Remove-Item -Path $modToImport -Force
        }
    }

}


Export-ModuleMember -Function Set-TerraformBackend
