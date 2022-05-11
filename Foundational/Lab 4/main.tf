resource "random_password" "pwd" {
  length      = 12
  special     = false
  min_lower   = 1
  min_numeric = 3
  min_upper   = 1
}

# create three rgs for vm, fw, peering in one go
resource "azurerm_resource_group" "resgrp" {
  location = var.RG_LOCATION
  name     = "${var.PREFIX}-${each.value}" #unique name will be picked
  tags     = var.TAGS
  for_each = var.RG_NAME # Looping to create multiple resource groups, based on value specified in set variable
}

# create virtual network for vm
module "VirtualNetwork" {
  source = "./modules/windows_virtual_network"
  #  Passing variables to child module from root module
  MOD_VNET_NAME           = "${var.PREFIX}-vnet"
  MOD_VNET_ADDRESS        = var.VNET_ADDRESS
  MOD_RG_LOCATION         = var.RG_LOCATION
  MOD_RG_NAME             = azurerm_resource_group.resgrp["vmrg"].name
  MOD_TAGS                = var.TAGS
  MOD_VNET_SUBNET_ADDRESS = var.VNET_SUBNET_ADDRESS
}

#create nic for virtual network, we will attach it to vm later on
resource "azurerm_network_interface" "nic" {
  location            = var.RG_LOCATION
  name                = "${var.PREFIX}-nic"
  resource_group_name = azurerm_resource_group.resgrp["vmrg"].name
  ip_configuration {
    name                          = "ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.VirtualNetwork.subnet-id[0]
  }
}

resource "azurerm_network_security_group" "nsg" {
  location            = var.RG_LOCATION
  name                = "${var.PREFIX}-nsg"
  resource_group_name = azurerm_resource_group.resgrp["vmrg"].name
  #  security_rule {
  #    access                     = "Allow"
  #    direction                  = "Inbound"
  #    name                       = "Allow_SSH"
  #    priority                   = 100
  #    protocol                   = "Tcp"
  #    source_port_range          = "*"
  #    destination_port_range     = "22"
  #    source_address_prefix      = "*"
  #    destination_address_prefix = "*"
  #  }
}

resource "azurerm_subnet_network_security_group_association" "association" {
  network_security_group_id = azurerm_network_security_group.nsg.id
  subnet_id                 = module.VirtualNetwork.subnet-id[0]
}

#Create Virtual network and subnet for Firewall
module "FwNetwork" {
  source = "./modules/windows_virtual_network"
  #  Passing variables to child module from root module
  MOD_VNET_NAME    = "${var.PREFIX}-FwNetwork"
  MOD_VNET_ADDRESS = var.FW_VNET_ADDRESS
  MOD_RG_LOCATION  = var.RG_LOCATION
  MOD_RG_NAME      = azurerm_resource_group.resgrp["fwrg"].name
  MOD_TAGS         = var.TAGS
}

# create peering connection between Virtual network for vm and Network for Firewall
module "vnet-peering" {
  source         = "./modules/vnet_peering"
  MOD_RG1_NAME   = azurerm_resource_group.resgrp["vmrg"].name
  MOD_VNET1_ID   = module.VirtualNetwork.nw-id
  MOD_VNET1_NAME = module.VirtualNetwork.nw-name
  MOD_RG2_NAME   = azurerm_resource_group.resgrp["fwrg"].name
  MOD_VNET2_ID   = module.FwNetwork.nw-id
  MOD_VNET2_NAME = module.FwNetwork.nw-name
}

#create Firewall in Firewall network
module "firewall" {
  source                  = "./modules/azure_firewall"
  MOD_TAGS                = var.TAGS
  MOD_VNET_NAME           = module.FwNetwork.nw-name
  MOD_VNET_SUBNET_ADDRESS = var.FW_VNET_SUBNET_ADDRESS
  MOD_RG_LOCATION         = var.RG_LOCATION # keeping location of firewall RG and normal RG same
  MOD_RG_NAME             = azurerm_resource_group.resgrp["fwrg"].name
}

resource "azurerm_firewall_policy_rule_collection_group" "fw_rcg" {
  firewall_policy_id = module.firewall.fw_policy_id
  name               = "${var.PREFIX}-rcg"
  priority           = 100
  depends_on         = [module.firewall.fw_name]

  nat_rule_collection {
    action   = "Dnat"
    name     = "AllowSSH"
    priority = 100

    rule {
      name                = "${var.PREFIX}-vm"
      source_addresses    = ["*"]
      protocols           = ["TCP"]
      destination_address = module.firewall.fw_pubip_ip
      destination_ports   = ["22"]
      translated_address  = azurerm_network_interface.nic.private_ip_address
      translated_port     = "22"
    }
  }

  nat_rule_collection {
    action   = "Dnat"
    name     = "AllowWebAccess"
    priority = 200

    rule {
      name                = "${var.PREFIX}-nginx"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = module.firewall.fw_pubip_ip
      destination_ports   = ["8000"]
      translated_address  = azurerm_network_interface.nic.private_ip_address
      translated_port     = 80
    }
  }
}

resource "random_id" "random" {
  byte_length = 2
}

resource "azurerm_storage_account" "sa" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.RG_LOCATION
  name                     = "${var.STORAGE_ACCOUNT}${random_id.random.hex}"
  resource_group_name      = azurerm_resource_group.resgrp["vmrg"].name
  tags                     = var.TAGS
}

resource "azurerm_virtual_machine" "vm" {
  location = var.RG_LOCATION
  name     = "${var.PREFIX}-vm"

  # referring child module output variables as an input in root module
  network_interface_ids         = [azurerm_network_interface.nic.id]
  resource_group_name           = azurerm_resource_group.resgrp["vmrg"].name
  vm_size                       = "Standard_DS1_v2"
  delete_os_disk_on_termination = true
  tags                          = var.TAGS

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.sa.primary_blob_endpoint
  }

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
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-vm"
    admin_username = var.USERNAME
    admin_password = random_password.pwd.result
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine_extension" "example" {
  name                       = "hostname"
  virtual_machine_id         = azurerm_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo apt-get install nginx -y"
    }
SETTINGS
  tags     = var.TAGS
}

data "azurerm_public_ip" "fw_pubip" {
  name                = module.firewall.fw_pubip_name
  resource_group_name = azurerm_resource_group.resgrp["fwrg"].name
}