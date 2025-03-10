locals {
  sanitized_name = lower(replace(var.name, "/[^a-z0-9]/", "-"))
  key_vault_name = "${local.sanitized_name}-vault"
  key_name       = "${local.sanitized_name}-key"

  container_sku = var.enable_key_vault ? "Confidential" : "Standard"
  key_type      = var.enable_key_vault ? "azure-skr" : "ephemeral"

  vnet_resource_group_name = var.vnet_resource_group != "" ? var.vnet_resource_group : azurerm_resource_group.main.name

  subnet_id = var.create_new_vnet ? (
    azurerm_subnet.main[0].id
    ) : (
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.vnet_resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name}/subnets/${var.subnet_name}"
  )

  attestation_policy = {
    version = "1.0.0"
    anyOf = [
      {
        authority = "https://sharedweu.weu.attest.azure.net"
        allOf = concat(
          [
            {
              claim  = "x-ms-attestation-type"
              equals = "sevsnpvm"
            },
            {
              claim  = "x-ms-compliance-status"
              equals = "azure-compliant-uvm"
            }
          ],
        )
      }
    ]
  }
}

resource "azurerm_resource_group" "main" {
  name     = "${local.sanitized_name}-rg"
  location = var.location
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${replace(lower(var.name), "-", "")}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true
}

# Import images to ACR
resource "null_resource" "import_images" {
  triggers = {
    acr_id = azurerm_container_registry.acr.id
  }

  provisioner "local-exec" {
    command = <<EOT
    az acr import --name ${azurerm_container_registry.acr.name} \
        --source "fr0ntierxpublic.azurecr.io/polaris-proxy":${var.polaris_proxy_image_version} \
      --image polaris-proxy:${var.polaris_proxy_image_version} \
      --force
    
    az acr import --name ${azurerm_container_registry.acr.name} \
      --source mcr.microsoft.com/aci/skr:2.7 \
      --image skr-sidecar:2.7 \
      --force
  EOT
  }
}

# Container Group
resource "azurerm_container_group" "main" {
  name                = "${local.sanitized_name}-aci"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  ip_address_type     = var.networking_type == "Private" ? "Private" : "Public"
  dns_name_label      = var.dns_name_label
  subnet_ids          = var.networking_type == "Private" ? [local.subnet_id] : null
  sku                 = local.container_sku
  dynamic "identity" {
    for_each = var.enable_key_vault ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  depends_on = [null_resource.import_images]

  # SKR Sidecar - tylko gdy enable_key_vault=true
  dynamic "container" {
    for_each = var.enable_key_vault ? [1] : []
    content {
      name   = "skr-sidecar-container"
      image  = "${azurerm_container_registry.acr.login_server}/skr-sidecar:2.7"
      cpu    = "1"
      memory = "1"

      commands = ["/skr.sh"]

      environment_variables = {
        "POLARIS_CONTAINER_AZURE_SKR_MAA_ENDPOINT" = "sharedweu.weu.attest.azure.net"
        "POLARIS_CONTAINER_AZURE_SKR_AKV_ENDPOINT" = "${local.key_vault_name}.vault.azure.net"
        "POLARIS_CONTAINER_AZURE_SKR_KID"          = local.key_name
      }

      ports {
        port     = 8080
        protocol = "TCP"
      }
    }
  }

  # Polaris Proxy
  container {
    name   = "polaris-secure-proxy"
    image  = "${azurerm_container_registry.acr.login_server}/polaris-proxy:${var.polaris_proxy_image_version}"
    cpu    = "1"
    memory = "1"

    environment_variables = {
      POLARIS_CONTAINER_KEY_TYPE                 = local.key_type
      POLARIS_CONTAINER_WORKLOAD_BASE_URL        = "http://localhost:${var.workload_port}"
      POLARIS_CONTAINER_ENABLE_INPUT_ENCRYPTION  = var.polaris_proxy_enable_input_encryption
      POLARIS_CONTAINER_ENABLE_OUTPUT_ENCRYPTION = var.polaris_proxy_enable_output_encryption
      POLARIS_CONTAINER_ENABLE_CORS              = var.polaris_proxy_enable_cors
      POLARIS_CONTAINER_ENABLE_LOGGING           = var.polaris_proxy_enable_logging
      POLARIS_CONTAINER_AZURE_SKR_MAA_ENDPOINT   = "sharedweu.weu.attest.azure.net"
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
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }

  dynamic "image_registry_credential" {
    for_each = var.registry_login_server != "" ? [1] : []
    content {
      server   = var.registry_login_server
      username = var.registry_username
      password = var.registry_password
    }
  }
}
