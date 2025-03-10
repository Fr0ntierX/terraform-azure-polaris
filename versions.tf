terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.22.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.9.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "4bd57494-c0a6-4ee2-b44d-8b398b4a8862"
}

data "azurerm_client_config" "current" {}