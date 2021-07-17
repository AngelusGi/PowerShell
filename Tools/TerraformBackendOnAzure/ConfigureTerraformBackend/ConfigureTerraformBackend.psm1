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

        # Verify if customer resource prefix lenght
        function Measure-CustomerPrefix {
            param (
                [Parameter(
                    HelpMessage = "Resource Prefix.",
                    Mandatory = $true)]
                [string]
                $ResourcePrefix,

                [Parameter(
                    HelpMessage = "Max lenght of resource prefix. Default: 10",
                    Mandatory = $false)]
                [int]
                $MaxLenght,

                [Parameter(
                    HelpMessage = "Min lenght of resource prefix. Default: 4",
                    Mandatory = $false)]
                [int]
                $MinLenght = 4
            )

            process {
                if (-not ($ResourcePrefix.Length -le $MaxLenght) -and ($ResourcePrefix.Length -ge $MinLenght)) {
                    Write-Error "La lunghezza del prefisso deve essere compresa tra $($MinLenght) e $($MaxLenght) caratteri."
                    exit
                }
            }
        }

        # This method manages the connection to Azure: it uses Device Authentication on WSL and Linux
        function Set-AzureConnect {
            process {
                if ([System.Environment]::OSVersion.Platform -ne "Win32NT") {
                    Connect-AzAccount -UseDeviceAuthentication -ErrorAction Stop
                }
                else {
                    Connect-AzAccount -ErrorAction Stop
                }
            }
        }

        # This method manages the connection to Azure: verifies if has been specified a subscrption in wich deploy resources
        function Set-AzureConnection {
            process {
                if ([string]::IsNullOrWhiteSpace($AzSub) -or [string]::IsNullOrEmpty($AzSub)) {
                    Set-AzureConnect
                    $actualAz = Get-AzContext
                }
                else {
                    Set-AzureConnect
                    $actualAz = Set-AzContext -Subscription $AzSub
                }
        
                Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Sottoscrizione attualmente in uso:"
                $temp = $actualAz | Select-Object Account, Subscription, Tenant
                Write-Host -ForegroundColor Green -BackgroundColor Black -Object $temp
            }
        }

        # Creates (if not exists) a Key Vault in the resource group on Azure
        function Set-AzKeyVault {
            param (
                [Parameter(
                    Mandatory = $false
                )]
                [ValidateSet("Standard", "Premium")]
                [string]
                $KeyVaultSku = "Standard",

                [Parameter(
                    Mandatory = $false
                )]
                [int]
                $RetentionDays = 90
            )

            process {
                if ([string]::IsNullOrEmpty($AzKeyVault) -or [string]::IsNullOrWhiteSpace($AzKeyVault)) {
                    $keyVaultName = $ResourcePrefix.ToLowerInvariant() + $random.ToString() + "-kv"
                }
                else {
                    # if key vault name is provided as script parameter
                    $keyVaultName = $AzKeyVault.ToLowerInvariant()
                }

                $keyVault = Get-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $ResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue

                if ($null -eq $keyVault) {
                    Write-Warning "Il KeyVault $($keyVaultName) indicato non esiste nel gruppo di risorse $($ResourceGroup.ResourceGroupName), creazione in corso..."
                    $keyVault = New-AzKeyVault -Name $keyVaultName -ResourceGroupName $ResourceGroup.ResourceGroupName -Location $ResourceGroup.Location -Sku $KeyVaultSku -EnablePurgeProtection -SoftDeleteRetentionInDays $RetentionDays -Tag $AzTag -ErrorAction Stop
                }
    
                $temp = $keyVault | Select-Object VaultName, ResourceGroupName, Location, Sku, SoftDeleteRetentionInDays, VaultUri, TagsTable
                Write-Host $temp
    
                return $keyVault
            }
        }

        # Saves on Azure Key Vault as secrets all keys from storage account used to store terraform states
        function Export-TerraformOnAzKeyVault {
            [CmdletBinding()]
            param (
                [object[]]
                $Keys,

                [Parameter(
                    Mandatory = $false
                )]
                [ValidateSet("Standard", "Premium")]
                [string]
                $KeyVaultSku = "Standard",
        
                [Parameter(
                    Mandatory = $false
                )]
                [int]
                $RetentionDays = 90
            )
    
            process {

                $keyVault = Set-AzKeyVault -KeyVaultSku $KeyVaultSku -RetentionDays $RetentionDays 

                foreach ($key in $Keys) {
                    $secureKey = ConvertTo-SecureString -String $key.Value -AsPlainText -Force
                    $secretAdded = Set-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name $key.KeyName -SecretValue $secureKey -Expires "01/01/2099" -ContentType "Storage Account - $($key.KeyName)" -Tag $AzTag -ErrorAction Stop
                    # Write-Output $secretAdded
                }
            }
        }

        # Populates the terraform output with the need information from Azure Blob Storage
        function Get-TerraformOutput {
            param (
                [Parameter(
                    Mandatory = $true
                )]
                $StorageAccount,
        
                [Parameter(
                    Mandatory = $true
                )]
                $StorageContainer,

                [Parameter(
                    Mandatory = $false
                )]
                $Extension = "tfstate",

                [Parameter(
                    Mandatory = $false
                )]
                $FileName = "terraform"
            )

            process {
                return "####################`n# Snippet generated by PowerShell to store Terraform states on Azure Storage`n####################`nterraform {`n`tbackend ""azurerm"" {`n`t`tresource_group_name = ""$($StorageAccount.ResourceGroupName)""`n`t`tstorage_account_name = ""$($StorageAccount.StorageAccountName)""`n`t`tcontainer_name = ""$($StorageContainer.Name)""`n`t`tkey = ""$($FileName).$($Extension)""`n`t}`n}`n"
            }
        }

        # Creates (if not exists) an resource group on Azure
        function Set-AzResourceGroup {
            process {
                if ([string]::IsNullOrEmpty($AzResGroup) -or [string]::IsNullOrWhiteSpace($AzResGroup)) {
                    $rgName = $ResourcePrefix
                }
                else {
                    # if resoruce group name is provided as script parameter
                    $rgName = $AzResGroup.ToLowerInvariant()
                }
        
                $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
        
                if ($null -eq $rg) {
                    Write-Warning "Il resource group $($rgName) indicato non esiste, creazione in corso..."
                    $rg = New-AzResourceGroup -Name $rgName -Location $AzRegion -Tag $AzTag -ErrorAction Stop
                }

                $temp = $rg | Select-Object ResourceGroupName, Location, ProvisioningState, ResourceId, TagsTable
                Write-Host $temp

                return $rg
            }
        }

        # Creates (if not exists) a storage account in the resource group on Azure
        function Set-AzStorage {
            param (
                [Parameter(
                    Mandatory = $true
                )]
                [object]
                $ResourceGroup,

                [Parameter(
                    Mandatory = $true
                )]
                [string]
                $StorageSku
            )

            process {
                if ([string]::IsNullOrEmpty($AzStorageAccount) -or [string]::IsNullOrWhiteSpace($AzStorageAccount)) {
                    $stgName = $ResourcePrefix.ToLowerInvariant() + $random.ToString() + "stg"
                }
                else {
                    # if resoruce group name is provided as script parameter
                    $stgName = $AzStorageAccount.ToLowerInvariant()
                }

                $stgNameAvailable = Get-AzStorageAccountNameAvailability -Name $stgName -ErrorAction Stop

                if ($stgNameAvailable.NameAvailable -eq $true) {
                    Write-Warning "Lo storage account $($stgName) indicato non esiste nel gruppo di risorse $($ResourceGroup.ResourceGroupName), creazione in corso..."
                    $stgAcc = New-AzStorageAccount -Name $stgName -ResourceGroupName $ResourceGroup.ResourceGroupName -SkuName $StorageSku -Location $ResourceGroup.Location -AccessTier Hot -Kind BlobStorage -Tag $AzTag -ErrorAction Stop
                }
                elseif ($stgNameAvailable.NameAvailable -eq $false) {

                    try {
                        $stgAcc = Get-AzStorageAccount -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $stgName
                    }
                    catch {
                        Write-Error "Il nome per lo strage account non è disponibile: $($stgName)"
                        exit
                    }

                }
                else {
                    Write-Error "Errore: $($stgNameAvailable.Message)"
                }

                $temp = $stgAcc | Select-Object StorageAccountName, Kind, AccessTier, EnableHttpsTrafficOnly, ProvisioningState, TagsTable
                Write-Host $temp

                return Set-AzStorageConfiguration -StorageAccount $stgAcc
            }
        }

        # Configures the Azure Storage Account and creates in it the Storage Container to store terraform states
        function Set-AzStorageConfiguration {
            param (
                [Parameter(
                    Mandatory = $true
                )]
                [object]
                $StorageAccount
            )
    
            process {
                $stgKeys = Get-AzStorageAccountKey -ResourceGroupName $StorageAccount.ResourceGroupName -Name $StorageAccount.StorageAccountName -ErrorAction Stop

                Export-TerraformOnAzKeyVault -Keys $stgKeys -KeyVaultSku $AzKvSku

                $stgKey = $stgKeys | Where-Object { $_.KeyName -Match "key1" }
                $stgContext = New-AzStorageContext -StorageAccountName $StorageAccount.StorageAccountName -StorageAccountKey $stgKey.Value -Protocol Https -ErrorAction Stop

                $stgContainer = Get-AzStorageContainer -Name $TerraformContainer -Context $stgContext -ErrorAction SilentlyContinue

                if ($null -eq $stgContainer) {
                    Write-Warning "Il container $($TerraformContainer) indicato non esiste nello storage account $($stgContext.StorageAccountName), creazione in corso..."
                    $stgContainer = New-AzStorageContainer -Name $TerraformContainer -Context $stgContext -ErrorAction Stop
                }

                $temp = $stgContainer | Select-Object Name, CloudBlobContainer.Uri.AbsoluteUri, PublicAccess
                Write-Host $temp

                return $StorageAccount, $stgContainer
            }
        }
        #endregion

        #region script body

        # generates a random value to use as postfix in resources' name
        $random = Get-Random -Maximum 99999

        Set-AzureConnection

        $rg = Set-AzResourceGroup

        $storageConfig = Set-AzStorage -ResourceGroup $rg -StorageSku $AzStgSku

        $terraformOutput = Get-TerraformOutput -StorageAccount $storageConfig[0] -StorageContainer $storageConfig[-1]

        # close PowerShell session on Azure
        Disconnect-AzAccount -InformationAction SilentlyContinue
        Write-Host -ForegroundColor Green -BackgroundColor Black -Object "Account Azure disconnesso."

        return $terraformOutput
    }
}

Export-ModuleMember -Function Set-TerraformBackend
