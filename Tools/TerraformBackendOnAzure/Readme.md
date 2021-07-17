# Module manager - PowerShell library

## Description

This custom module verify if the module is alredy installed, otherwise will install/update it.
It can manage GitHub hosted modules too, such as Azure Lab Services.

## How to use it

```Test-TerraformBackendOnAzure.ps1``` is an example thath shows how to use it.

## Parameters

### Other parameters

#### Parameter ResourcePrefix

Resource prefix (e.g. project name).
**Default**: TfBackend

#### Parameter MainFilePath

Path from wich will be imported the output Main.tf without the backend configuration. Default: script execution folder.

#### Parameter OutputFilePath

Path where will be saved the output Main.tf within the backend configuration. Default: script execution folder.

#### Parameter MinLenght

Min lenght of resource prefix. Default: 4.

#### Parameter MaxLenght

Max lenght of resource prefix. Default: 10.

TODO

### Azure parameters

#### Parameter AzSub

Azure Subscription Name or Id.

#### Parameter AzRegion

Azure region name.
**Default**: westeurope.

#### Parameter AzTag

Azure Tag.
**Default**: {
    app = 'TerraformBackend'
    iac = 'PowerShell'
    }

#### Parameter AzResGroup

Resource Group Name.
Automatically will be added the postfix '-rg' to the ResourcePrefix parameter.
**Default**: TfBackend-rg

#### Parameter AzStgSku

SKU of the Storage Account.
**Default**: Standard_LRS

#### Parameter AzStorageAccount

Storage Account Name.
Automatically will be added the postfix 'stg' to the ResourcePrefix parameter.
**Default**: tfbackend1234stg

#### Parameter TerraformContainer

TODO

#### Parameter AzKeyVault

Key Vault Name.
Automatically will be added the postfix '-kv' to the ResourcePrefix parameter.
**Default**: TfBackend1234-kv

#### Parameter AzKvSku

SKU of the Key Vault.
**Default**: Standard

### Terraform parameters

#### Parameter MainTerraformFileName

Name of the main Terraform file (no extension required).
**Default**: main
