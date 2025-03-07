# Use the Terraform resource directly
resource "azurerm_attestation_provider" "main" {
  count               = var.enable_kms ? 1 : 0
  name                = replace(lower("${var.name}attestation"), "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Create federated identity credentials - similar to GCP workload identity federation
resource "azurerm_federated_identity_credential" "attestation" {
  count               = var.enable_kms && var.attestation_federated_identity_enabled ? 1 : 0
  name                = "${var.name}-attestation-federated"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.main.id
  audience            = ["api://AzureADTokenExchange"]
  
  # Reference the attestation provider directly
  issuer              = azurerm_attestation_provider.main[0].attestation_uri
  subject             = "https://azure.attestation.net/${var.name}"
}

# Create a storage account for diagnostic logs
resource "azurerm_storage_account" "logs" {
  name                     = "${replace(lower(var.name), "-", "")}logs"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Monitor diagnostic settings for Key Vault - updated to use enabled_log instead of log
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count              = var.enable_kms ? 1 : 0
  name               = "key-vault-logs"
  target_resource_id = azurerm_key_vault.main[0].id
  storage_account_id = azurerm_storage_account.logs.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Add storage lifecycle policy instead of retention_policy
resource "azurerm_storage_management_policy" "logs_retention" {
  storage_account_id = azurerm_storage_account.logs.id

  rule {
    name    = "logs-retention"
    enabled = true
    filters {
      prefix_match = ["insights-logs-auditevent"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 30
      }
    }
  }
}
