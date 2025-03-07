# Initialize the Azure providers with the subscription ID from variable
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

# Remove the empty provider block
# provider "azuread" {
#   # No additional configuration needed
# }
