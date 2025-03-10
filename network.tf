resource "azurerm_virtual_network" "main" {
  count               = var.create_new_vnet ? 1 : 0
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  count                = var.create_new_vnet ? 1 : 0
  name                 = var.subnet_name
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