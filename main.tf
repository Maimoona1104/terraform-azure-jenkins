resource "azurerm_resource_group" "example" {
  name     = "rg-${var.environment}-${var.project_name}"
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source              = "./modules/vnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  vnet_name           = "vnet-${var.environment}-${var.project_name}"
  address_space       = ["10.0.0.0/16"]
  subnets = {
    "default" = "10.0.1.0/24"
  }
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "example" {
  count                           = var.vm_count
  name                            = "vm-${var.environment}-${var.project_name}-${count.index}"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.example[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  tags = var.tags
}

resource "azurerm_network_interface" "example" {
  count               = var.vm_count
  name                = "nic-${var.environment}-${var.project_name}-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.subnet_ids["default"]
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}
