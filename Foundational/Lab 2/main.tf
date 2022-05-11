resource "azurerm_resource_group" "resgrp" {
  location = var.RG_LOCATION
  name     = "${var.PREFIX}-rg"
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = [var.VNET_ADDRESS]
  location            = azurerm_resource_group.resgrp.location
  name                = "${var.PREFIX}-vnet"
  resource_group_name = azurerm_resource_group.resgrp.name
}

resource "azurerm_subnet" "sub" {
  name                 = "${var.PREFIX}-sub"
  resource_group_name  = azurerm_resource_group.resgrp.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.VNET_SUBNET1_ADDRESS]
}

resource "azurerm_public_ip" "pubip" {
  allocation_method   = "Dynamic"
  location            = var.RG_LOCATION
  name                = "${var.PREFIX}-pubip"
  resource_group_name = azurerm_resource_group.resgrp.name
}

resource "azurerm_network_interface" "nic" {
  location            = var.RG_LOCATION
  name                = "${var.PREFIX}-nic"
  resource_group_name = azurerm_resource_group.resgrp.name
  ip_configuration {
    name                          = "ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.sub.id
    public_ip_address_id          = azurerm_public_ip.pubip.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  location            = var.RG_LOCATION
  name                = "${var.PREFIX}-nsg"
  resource_group_name = azurerm_resource_group.resgrp.name

  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "Allow_22"
    priority                   = 200
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "association" {
  network_security_group_id = azurerm_network_security_group.nsg.id
  subnet_id                 = azurerm_subnet.sub.id
}

resource "azurerm_virtual_machine" "vm" {
  location                      = var.RG_LOCATION
  name                          = "${var.PREFIX}-vm"
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
    name              = "${var.PREFIX}-osdisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-vm"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

data "azurerm_public_ip" "datapubip" {
  name                = azurerm_public_ip.pubip.name
  resource_group_name = azurerm_resource_group.resgrp.name
  depends_on          = [azurerm_virtual_machine.vm]
}