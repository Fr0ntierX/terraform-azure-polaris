resource "azurerm_user_assigned_identity" "main" {
  name                = "${var.name}-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Combined role assignment for key usage and attestation
resource "azurerm_role_assignment" "kv_crypto" {
  count                = var.enable_kms ? 1 : 0
  scope                = azurerm_key_vault.main[0].id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# Skip the attestation reader role for now - we'll add it later once everything works
# resource "azurerm_role_assignment" "attestation_reader" {
#   count                = var.enable_kms ? 1 : 0
#   scope                = azurerm_attestation_provider.main[0].id
#   role_definition_name = "Attestation Reader" 
#   principal_id         = azurerm_user_assigned_identity.main.principal_id
# }

resource "time_sleep" "wait_for_permissions" {
  count           = var.enable_kms ? 1 : 0
  depends_on      = [azurerm_role_assignment.kv_crypto] # Remove attestation_reader from here too
  create_duration = "30s"
}