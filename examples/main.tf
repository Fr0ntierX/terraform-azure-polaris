# Define Azure provider at the root level
provider "azurerm" {
  features {}
  subscription_id = "4bd57494-c0a6-4ee2-b44d-8b398b4a8862"
}

# Keep the azuread provider for authentication
provider "azuread" {
  tenant_id = "2cf53577-d63e-40c3-9d3b-ee93caa19b41"
}

module "polaris_azure_module" {
  source = "../"
  
  # No need for providers block since we're not using provider inheritance
  
  name                = "anonym-ser-3"
  location            = "West Europe"
  enable_kms          = true
  vm_size             = "Standard_D4s_v5"
  ssh_public_key_path = chomp(file("${path.module}/karol-key.pub"))
  
  # Pass subscription ID to the module
  azure_subscription_id = "4bd57494-c0a6-4ee2-b44d-8b398b4a8862"

  polaris_proxy_image         = "fr0ntierx/polaris-proxy"
  polaris_proxy_port          = 3000
  polaris_proxy_source_ranges = ["192.168.1.0/24"]

  workload_image    = "fr0ntierx/anonymization-service"
  workload_port     = 8000
  workload_env_vars = {
    "ENV_VAR1" = "value1"
    "ENV_VAR2" = "value2"
  }
}
