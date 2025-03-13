locals {
  sanitized_name = lower(replace(var.name, "/[^a-z0-9]/", "-"))
  key_vault_name = "${local.sanitized_name}-vault"
  key_name       = "${local.sanitized_name}-key"

  vnet_name   = var.new_vnet_enabled ? "${local.sanitized_name}-vnet" : var.vnet_name
  subnet_name = "${local.sanitized_name}-subnet"

  container_sku = "Confidential"
  key_type      = var.enable_key_vault ? "azure-skr" : "ephemeral"

  vnet_resource_group_name = var.vnet_resource_group != "" ? var.vnet_resource_group : azurerm_resource_group.main.name

  subnet_id = var.new_vnet_enabled ? (
    azurerm_subnet.main[0].id
    ) : (
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.vnet_resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}/subnets/${local.subnet_name}"
  )
}

resource "azurerm_resource_group" "main" {
  name     = "${local.sanitized_name}-rg"
  location = var.location
}


resource "azurerm_container_group" "main" {
  name                = "${local.sanitized_name}-aci"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  ip_address_type     = var.networking_type == "Private" ? "Private" : "Public"
  dns_name_label      = var.networking_type == "Private" ? null : var.dns_name_label
  subnet_ids          = var.networking_type == "Private" ? [local.subnet_id] : null
  sku                 = local.container_sku
  dynamic "identity" {
    for_each = var.enable_key_vault ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "container" {
    for_each = var.enable_key_vault ? [1] : []
    content {
      name   = "skr-sidecar-container"
      image  = "mcr.microsoft.com/aci/skr:2.7"
      cpu    = "1"
      memory = "1"

      commands = ["/skr.sh"]

      ports {
        port     = 8080
        protocol = "TCP"
      }
    }
  }

  # Polaris Proxy
  container {
    name   = "polaris-secure-proxy"
    image  = "fr0ntierxpublic.azurecr.io/polaris-proxy:${var.polaris_proxy_image_version}"
    cpu    = "1"
    memory = "1"

    environment_variables = {
      POLARIS_CONTAINER_KEY_TYPE                 = local.key_type
      POLARIS_CONTAINER_WORKLOAD_BASE_URL        = "http://localhost:${var.workload_port}"
      POLARIS_CONTAINER_ENABLE_INPUT_ENCRYPTION  = var.polaris_proxy_enable_input_encryption
      POLARIS_CONTAINER_ENABLE_OUTPUT_ENCRYPTION = var.polaris_proxy_enable_output_encryption
      POLARIS_CONTAINER_ENABLE_CORS              = var.polaris_proxy_enable_cors
      POLARIS_CONTAINER_ENABLE_LOGGING           = var.polaris_proxy_enable_logging
      POLARIS_CONTAINER_AZURE_SKR_MAA_ENDPOINT   = var.maa_endpoint
      POLARIS_CONTAINER_AZURE_SKR_AKV_ENDPOINT   = "${local.key_vault_name}.vault.azure.net"
      POLARIS_CONTAINER_AZURE_SKR_KID            = local.key_name
    }

    ports {
      port     = var.polaris_proxy_port
      protocol = "TCP"
    }
  }

  # Client workload
  container {
    name   = "workload"
    image  = var.registry_login_server != "" ? "${var.registry_login_server}/${var.workload_image}" : var.workload_image
    cpu    = var.container_cpu
    memory = var.container_memory

    environment_variables = var.workload_env_vars
    commands              = var.workload_arguments

    ports {
      port     = var.workload_port
      protocol = "TCP"
    }
  }

  image_registry_credential {
    server   = var.registry_login_server
    username = var.registry_username
    password = var.registry_password
  }
}
