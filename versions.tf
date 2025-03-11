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
    subscription_id = var.subscriptionId
}

data "azurerm_client_config" "current" {}