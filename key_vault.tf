resource "azurerm_key_vault" "main" {
  count = var.enable_key_vault ? 1 : 0

  name                        = local.key_vault_name
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true

  access_policy = []
}

resource "azurerm_key_vault_access_policy" "container" {
  count        = var.enable_key_vault ? 1 : 0
  key_vault_id = azurerm_key_vault.main[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_container_group.main.identity[0].principal_id

  key_permissions = [
    "Get", "Release"
  ]
}

resource "azurerm_key_vault_access_policy" "deployer" {
  count        = var.enable_key_vault ? 1 : 0
  key_vault_id = azurerm_key_vault.main[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Create", "Delete",
    "Update", "Import", "Recover", "Backup", "Restore",
    "Decrypt", "Sign", "Verify", "WrapKey", "UnwrapKey",
    "GetRotationPolicy", "SetRotationPolicy", "Purge"
  ]

  certificate_permissions = [
    "Get"
  ]

  secret_permissions = [
    "Get"
  ]
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

  body = {
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
  }

  depends_on = [
    azurerm_key_vault.main,
    azurerm_key_vault_access_policy.deployer
  ]
}