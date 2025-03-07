output "vm_public_ip" {
  value = try(azurerm_public_ip.main[0].ip_address, "No public IP assigned")
}

output "key_vault_name" {
  value = var.enable_kms ? azurerm_key_vault.main[0].name : "KMS disabled"
}

output "managed_identity_client_id" {
  value = azurerm_user_assigned_identity.main.client_id
}

output "polaris_proxy_endpoint" {
  value = "http://${try(azurerm_public_ip.main[0].ip_address, "No public IP")}:${var.polaris_proxy_port}"
}

output "workload_endpoint" {
  value = "http://${try(azurerm_public_ip.main[0].ip_address, "No public IP")}:${var.workload_port}"
}