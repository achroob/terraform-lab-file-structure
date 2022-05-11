resource "azurerm_resource_group" "resgrp" {
  location = "northeurope"
  name     = "demo-rg"
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resgrp.location
  name                = "demo-vnet"
  resource_group_name = azurerm_resource_group.resgrp.name
}

resource "azurerm_subnet" "sub" {
  name                 = "demo-sub"
  resource_group_name  = azurerm_resource_group.resgrp.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_interface" "nic" {
  location            = azurerm_resource_group.resgrp.location
  name                = "demo-nic"
  resource_group_name = azurerm_resource_group.resgrp.name
  ip_configuration {
    name                          = "ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.sub.id
  }
}

resource "azurerm_virtual_machine" "vm" {
  location                      = azurerm_resource_group.resgrp.location
  name                          = "demo-vm"
  network_interface_ids         = [azurerm_network_interface.nic.id]
  resource_group_name           = azurerm_resource_group.resgrp.name
  vm_size                       = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    create_option     = "FromImage"
    name              = "demo-osdisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "demo-vm"
    admin_username = "linuxusr"
    admin_password = "Admin@890"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

data "azurerm_network_interface" "pvtip" {
  name                = azurerm_network_interface.nic.name
  resource_group_name = azurerm_resource_group.resgrp.name
}

output "privateip" {
  value = data.azurerm_network_interface.pvtip.private_ip_address
}