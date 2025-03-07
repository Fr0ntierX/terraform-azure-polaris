# Pobiera informacje o bieżącej konfiguracji klienta Azure
data "azurerm_client_config" "current" {}

# Tworzy Azure Key Vault jeśli włączona jest obsługa KMS
resource "azurerm_key_vault" "main" {
  count                       = var.enable_kms ? 1 : 0
  name                        = "${var.name}-kv"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"

  # Używamy tradycyjnego modelu dostępu przez access policy zamiast RBAC
  enable_rbac_authorization = false

  # Dostęp dla tożsamości zarządzanej, która będzie używana przez maszynę wirtualną
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.main.principal_id

    key_permissions = [
      "Get", "List", "Create", "Delete",
      "Decrypt", "Encrypt", "UnwrapKey",
      "WrapKey", "Verify", "Sign", "Purge",
      "GetRotationPolicy", "SetRotationPolicy"  # Uprawnienia do polityki rotacji klucza
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }

  # Dostęp dla tożsamości wykonującej Terraform (np. Twojego użytkownika lub service principal)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete",
      "Decrypt", "Encrypt", "UnwrapKey",
      "WrapKey", "Verify", "Sign", "Purge",
      "GetRotationPolicy", "SetRotationPolicy"  # Uprawnienia do polityki rotacji klucza
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }
}

# Dodaje czas oczekiwania po aktualizacji Key Vault
# aby upewnić się, że wszystkie uprawnienia są w pełni zastosowane
resource "time_sleep" "wait_for_keyvault" {
  count           = var.enable_kms ? 1 : 0
  depends_on      = [azurerm_key_vault.main]
  create_duration = "30s"
}

# Tworzy klucz w Key Vault
resource "azurerm_key_vault_key" "main" {
  count        = var.enable_kms ? 1 : 0
  depends_on   = [time_sleep.wait_for_keyvault]
  name         = "${var.name}-key"
  key_vault_id = azurerm_key_vault.main[0].id
  key_type     = "RSA"
  key_size     = 4096

  # Prosta polityka rotacji, aby uniknąć odczytu istniejącej polityki
  rotation_policy {
    automatic {
      time_after_creation = "P90D" # 90 dni po utworzeniu
    }
    expire_after         = "P360D" # Wygasa po 360 dniach
    notify_before_expiry = "P30D"  # Powiadomienie 30 dni przed wygaśnięciem
  }

  key_opts = [
    "decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"
  ]
}

# Give the attestation provider automatic access through VM identity
# This replaces the explicit attestation service principal ID reference
resource "azurerm_role_assignment" "attestation_key_access" {
  count                = var.enable_kms ? 1 : 0
  scope                = azurerm_key_vault.main[0].id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  
  # Add a description to clarify this is for attestation
  description          = "Allow TPM attestation to access keys"
}

# No need for explicit access policy since we're using RBAC assignment above