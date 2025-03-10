resource "azurerm_key_vault" "main" {
  count = var.enable_key_vault ? 1 : 0

  name                        = local.key_vault_name
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  enabled_for_disk_encryption = true

  # Access policy for Container Group
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_container_group.main.identity[0].principal_id

    key_permissions = [
      "Get", "Release"
    ]
  }

  # Access policy for Terraform principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete",
      "Update", "Import", "Recover", "Backup", "Restore",
      "Decrypt", "Sign", "Verify", "WrapKey", "UnwrapKey",
      "GetRotationPolicy", "SetRotationPolicy", "Purge"
    ]
  }
}

resource "azurerm_role_assignment" "main" {
  count = var.enable_key_vault ? 1 : 0

  scope                = azurerm_key_vault.main[0].id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_container_group.main.identity[0].principal_id
}

resource "azapi_resource" "kv_key" {
  count = var.enable_key_vault ? 1 : 0

  type      = "Microsoft.KeyVault/vaults/keys@2023-02-01"
  name      = local.key_name
  parent_id = azurerm_key_vault.main[0].id

  body = jsonencode({
    properties = {
      kty     = "RSA-HSM"
      keySize = 4096
      attributes = {
        exportable = true
      }
      keyOps = [
        "encrypt", "decrypt", "sign", "verify", "wrapKey", "unwrapKey"
      ]
      release_policy = {
        contentType = "application/json; charset=utf-8"
        data        = base64encode(jsonencode(local.attestation_policy))
      }
    }
  })

  depends_on = [
    azurerm_key_vault.main
  ]
}