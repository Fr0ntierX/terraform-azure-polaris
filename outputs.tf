output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "container_group_name" {
  description = "Name of the container group"
  value       = azurerm_container_group.main.name
}

output "container_group_ip" {
  description = "IP address of the container group"
  value       = var.networking_type == "Public" ? azurerm_container_group.main.ip_address : null
}

output "container_group_fqdn" {
  description = "FQDN of the container group"
  value       = var.networking_type == "Public" ? azurerm_container_group.main.fqdn : null
}

output "key_vault_name" {
  description = "Name of the key vault"
  value       = var.enable_key_vault ? azurerm_key_vault.main[0].name : null
}

output "key_vault_uri" {
  description = "URI of the key vault"
  value       = var.enable_key_vault ? azurerm_key_vault.main[0].vault_uri : null
}

output "key_name" {
  description = "Name of the key"
  value       = var.enable_key_vault ? local.key_name : null
}