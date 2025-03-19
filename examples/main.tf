module "polaris_azure_module" {
  source = "Fr0ntierX/polaris/azure"

  subscription_id = "your-subscription-id"
  
  name     = "polaris-example"
  location = "West Europe"

  # Security & Encryption
  enable_key_vault = true

  # Container Resources
  container_memory = 4
  container_cpu    = 2

  # Networking Configuration
  networking_type  = "Public" 

  # Polaris Proxy Configuration
  polaris_proxy_enable_input_encryption  = true
  polaris_proxy_enable_output_encryption = true
  polaris_proxy_enable_cors           = true
  polaris_proxy_enable_logging        = true

  # Workload Configuration
  registry_login_server = "fr0ntierxpublicdev.azurecr.io"
  registry_username     = "fr0ntierxpublicdev"
  registry_password     = "4KSWNjq8hpWUZnfILdhWwoumK6Gw7lncPagTJOgpVR+ACRAt/7Ko"
  workload_image        = "anonymization-service:latest"
  workload_port         = 8000
}