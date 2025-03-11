locals {
  networking_validation = (
    var.new_vnet_enabled == true || var.networking_type == "Private"
    ? true
    : tobool("ERROR: When connecting to an existing VNet (new_vnet_enabled = false), networking_type must be set to 'Private'. Public networking is only available with newly created networks.")
  )

  effective_networking_type = var.new_vnet_enabled == false ? "Private" : var.networking_type
}

resource "azurerm_virtual_network" "main" {
  count               = var.new_vnet_enabled ? 1 : 0
  name                = local.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  count                = var.new_vnet_enabled ? 1 : 0
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [var.subnet_address_prefix]

  delegation {
    name = "aciDelegation"

    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
    }
  }
}

resource "azurerm_network_security_group" "main" {
  count               = var.new_vnet_enabled && local.effective_networking_type == "Private" ? 1 : 0
  name                = "${local.sanitized_name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_rule" "polaris_proxy" {
  count                       = var.new_vnet_enabled && local.effective_networking_type == "Private" && length(var.polaris_proxy_source_ranges) > 0 ? 1 : 0
  name                        = "allow-polaris-proxy"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = var.polaris_proxy_port
  source_address_prefixes     = var.polaris_proxy_source_ranges
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main[0].name
}

resource "azurerm_network_security_rule" "deny_all" {
  count                       = var.new_vnet_enabled && local.effective_networking_type == "Private" && length(var.polaris_proxy_source_ranges) > 0 ? 1 : 0
  name                        = "deny-all-other"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = var.polaris_proxy_port
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main[0].name
}

resource "azurerm_subnet_network_security_group_association" "main" {
  count                     = var.new_vnet_enabled && local.effective_networking_type == "Private" ? 1 : 0
  subnet_id                 = azurerm_subnet.main[0].id
  network_security_group_id = azurerm_network_security_group.main[0].id
}