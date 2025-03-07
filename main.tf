resource "azurerm_resource_group" "main" {
  name     = "${var.name}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "${var.name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "main" {
  count               = var.public_ip_type != "NONE" ? 1 : 0
  name                = "${var.name}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = var.public_ip_type
  sku                 = "Standard"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.name}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_type != "NONE" ? azurerm_public_ip.main[0].id : null
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = "${var.name}-vm"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = var.vm_size
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.main.id]

  secure_boot_enabled = true
  vtpm_enabled        = true

  admin_ssh_key {
    username   = "adminuser"
    public_key = var.ssh_public_key_path
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.boot_disk_type
    disk_size_gb         = var.boot_disk_size
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-confidential-vm-jammy"
    sku       = "22_04-lts-cvm"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yml", {
    enable_kms                  = var.enable_kms
    key_vault_name              = var.enable_kms ? azurerm_key_vault.main[0].name : ""
    key_name                    = var.enable_kms ? azurerm_key_vault_key.main[0].name : ""
    managed_identity_client_id  = azurerm_user_assigned_identity.main.client_id
    polaris_proxy_image         = var.polaris_proxy_image
    polaris_proxy_image_version = var.polaris_proxy_image_version
    workload_image              = var.workload_image
    workload_port               = var.workload_port
    polaris_proxy_port          = var.polaris_proxy_port
    workload_env_vars           = var.workload_env_vars  # Pass directly, it's already a map
    workload_entrypoint         = var.workload_entrypoint
    workload_arguments          = var.workload_arguments
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    attestation_provider_name   = var.enable_kms ? replace(lower("${var.name}attestation"), "-", "") : ""
    attestation_provider_uri    = var.enable_kms ? azurerm_attestation_provider.main[0].attestation_uri : ""
    polaris_proxy_enable_input_encryption  = var.polaris_proxy_enable_input_encryption
    polaris_proxy_enable_output_encryption = var.polaris_proxy_enable_output_encryption
    polaris_proxy_enable_cors             = var.polaris_proxy_enable_cors
    polaris_proxy_enable_logging          = var.polaris_proxy_enable_logging
    key_type                    = "azure-federated"
    location                    = var.location
  }))

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-polaris-proxy"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.polaris_proxy_port
    source_address_prefixes    = var.polaris_proxy_source_ranges
    destination_address_prefix = "*"
  }
}
