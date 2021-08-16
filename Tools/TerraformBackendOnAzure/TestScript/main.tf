## Main terraform file - EXAMPLE

## Providers

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.67.0"
    }

    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.5"
    }
  }
}

provider "azurecaf" {
  features {}
}

provider "azurerm" {
  features {}
}


