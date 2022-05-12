resource "random_password" "pwd" {
  length      = 12
  special     = false
  min_lower   = 1
  min_numeric = 3
  min_upper   = 1
}

# create rgs for vm, fw in one go
module "resgrp" {
  source          = "./modules/resource_groups"
  MOD_PREFIX      = var.PREFIX
  MOD_RG_LOCATION = var.RG_LOCATION
  MOD_RG_NAME     = var.RG_NAME
  MOD_TAGS        = var.TAGS
}

# create virtual network/Subnet for linux vm
module "LxNetwork" {
  source = "./modules/virtual_network"
  #  Passing variables to child module from root module
  MOD_VNET_NAME           = "${var.PREFIX}-lx-vnet"
  MOD_VNET_ADDRESS        = var.LX_VNET_ADDRESS
  MOD_RG_LOCATION         = var.RG_LOCATION
  MOD_RG_NAME             = module.resgrp.rgrp["lxvmrg"].name
  MOD_TAGS                = var.TAGS
  MOD_VNET_SUBNET_ADDRESS = var.LX_VNET_SUBNET_ADDRESS
}

# create virtual network/Subnet for win vm
module "WinNetwork" {
  source = "./modules/virtual_network"
  #  Passing variables to child module from root module
  MOD_VNET_NAME           = "${var.PREFIX}-win-vnet"
  MOD_VNET_ADDRESS        = var.WIN_VNET_ADDRESS
  MOD_RG_LOCATION         = var.RG_LOCATION
  MOD_RG_NAME             = module.resgrp.rgrp["winvmrg"].name
  MOD_TAGS                = var.TAGS
  MOD_VNET_SUBNET_ADDRESS = var.WIN_VNET_SUBNET_ADDRESS
}

#Create Virtual network for Firewall
module "FwNetwork" {
  source = "./modules/virtual_network"
  #  Passing variables to child module from root module
  MOD_VNET_NAME    = "${var.PREFIX}-FwNetwork"
  MOD_VNET_ADDRESS = var.FW_VNET_ADDRESS
  MOD_RG_LOCATION  = var.RG_LOCATION
  MOD_RG_NAME      = module.resgrp.rgrp["fwrg"].name
  #Mandatory for Firewall Subnet/Network
  MOD_VNET_SUBNET_NAME    = ["AzureFirewallSubnet"]
  MOD_TAGS                = var.TAGS
  MOD_VNET_SUBNET_ADDRESS = var.FW_VNET_SUBNET_ADDRESS
}

#create nic for virtual network, we will attach it to vm later on
resource "azurerm_network_interface" "lxnic" {
  location            = var.RG_LOCATION
  name                = "${var.PREFIX}-lx-nic"
  resource_group_name = module.resgrp.rgrp["lxvmrg"].name
  ip_configuration {
    name                          = "ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.LxNetwork.subnet-id[0]
  }
}

# create generic nsg, otherwise you will not have any access
resource "azurerm_network_security_group" "lxnsg" {
  location            = var.RG_LOCATION
  name                = "${var.PREFIX}-lx-nsg"
  resource_group_name = module.resgrp.rgrp["lxvmrg"].name
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

# Associate Linux nsg with subnet
resource "azurerm_subnet_network_security_group_association" "lxsubnsg" {
  network_security_group_id = azurerm_network_security_group.lxnsg.id
  subnet_id                 = module.LxNetwork.subnet-id[0]
}

resource "azurerm_public_ip" "win-pubip" {
  allocation_method   = "Dynamic"
  location            = var.RG_LOCATION
  name                = "${var.PREFIX}-win.pubip"
  resource_group_name = module.resgrp.rgrp["winvmrg"].name
  tags                = var.TAGS
}

#create nic for virtual network, we will attach it to vm later on
resource "azurerm_network_interface" "winnic" {
  location            = var.RG_LOCATION
  name                = "${var.PREFIX}-win-nic"
  resource_group_name = module.resgrp.rgrp["winvmrg"].name
  ip_configuration {
    name                          = "ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.WinNetwork.subnet-id[0]
    public_ip_address_id          = azurerm_public_ip.win-pubip.id
  }
}

# create generic nsg, otherwise you will not have any access. Rules are not specified because
# communication is allowed between virtual networks
resource "azurerm_network_security_group" "winnsg" {
  location            = var.RG_LOCATION
  name                = "${var.PREFIX}-win-nsg"
  resource_group_name = module.resgrp.rgrp["winvmrg"].name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "Allow_RDP"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate Win nsg with subnet
resource "azurerm_subnet_network_security_group_association" "winsubnsg" {
  network_security_group_id = azurerm_network_security_group.winnsg.id
  subnet_id                 = module.WinNetwork.subnet-id[0]
}

# create peering connection between Linux Virtual network for vm and Network for Firewall
module "lx-vnet-peering" {
  source         = "./modules/virtual_network_peering"
  MOD_RG1_NAME   = module.resgrp.rgrp["lxvmrg"].name
  MOD_VNET1_ID   = module.LxNetwork.nw-id
  MOD_VNET1_NAME = module.LxNetwork.nw-name
  MOD_RG2_NAME   = module.resgrp.rgrp["fwrg"].name
  MOD_VNET2_ID   = module.FwNetwork.nw-id
  MOD_VNET2_NAME = module.FwNetwork.nw-name
}

# create peering connection between Win Virtual network for vm and Network for Firewall
#module "win-vnet-peering" {
#  source         = "./modules/virtual_network_peering"
#  MOD_RG1_NAME   = module.resgrp.rgrp["winvmrg"].name
#  MOD_VNET1_ID   = module.WinNetwork.nw-id
#  MOD_VNET1_NAME = module.WinNetwork.nw-name
#  MOD_RG2_NAME   = module.resgrp.rgrp["fwrg"].name
#  MOD_VNET2_ID   = module.FwNetwork.nw-id
#  MOD_VNET2_NAME = module.FwNetwork.nw-name
#}

# create peering connection between Win Virtual network for vm and Linux Virtual Network
module "win-lx-vnet-peering" {
  source         = "./modules/virtual_network_peering"
  MOD_RG1_NAME   = module.resgrp.rgrp["winvmrg"].name
  MOD_VNET1_ID   = module.WinNetwork.nw-id
  MOD_VNET1_NAME = module.WinNetwork.nw-name
  MOD_RG2_NAME   = module.resgrp.rgrp["lxvmrg"].name
  MOD_VNET2_ID   = module.LxNetwork.nw-id
  MOD_VNET2_NAME = module.LxNetwork.nw-name
}

#create Firewall in Firewall network
module "firewall" {
  source             = "./modules/azure_firewall"
  MOD_TAGS           = var.TAGS
  MOD_VNET_NAME      = module.FwNetwork.nw-name
  MOD_VNET_SUBNET_ID = module.FwNetwork.subnet-id[0]
  MOD_RG_LOCATION    = var.RG_LOCATION # keeping location of firewall RG and normal RG same
  MOD_RG_NAME        = module.resgrp.rgrp["fwrg"].name
}

#create firewall policy to connect to linux machine using publicip of firewall
resource "azurerm_firewall_policy_rule_collection_group" "fw-rcg" {
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
      translated_address  = azurerm_network_interface.lxnic.private_ip_address
      translated_port     = "22"
    }
  }
}

resource "random_id" "random" {
  byte_length = 2
}

resource "azurerm_storage_account" "lx-sa" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.RG_LOCATION
  name                     = "${var.STORAGE_ACCOUNT["lxvmrg"]}${random_id.random.hex}"
  resource_group_name      = module.resgrp.rgrp["lxvmrg"].name
  tags                     = var.TAGS
}

resource "azurerm_storage_account" "win-sa" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.RG_LOCATION
  name                     = "${var.STORAGE_ACCOUNT["winvmrg"]}${random_id.random.hex}"
  resource_group_name      = module.resgrp.rgrp["winvmrg"].name
  tags                     = var.TAGS
}

resource "azurerm_virtual_machine" "lxvm" {
  location = var.RG_LOCATION
  name     = "${var.PREFIX}-lx-vm"

  # referring child module output variables as an input in root module
  network_interface_ids         = [azurerm_network_interface.lxnic.id]
  resource_group_name           = module.resgrp.rgrp["lxvmrg"].name
  vm_size                       = "Standard_DS1_v2"
  delete_os_disk_on_termination = true
  tags                          = var.TAGS

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.lx-sa.primary_blob_endpoint
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    create_option     = "FromImage"
    name              = "${var.PREFIX}-lx-osdisk"
    caching           = "ReadWrite"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-lx-vm"
    admin_username = var.LX_USERNAME
    admin_password = random_password.pwd.result
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine" "winvm" {
  location = var.RG_LOCATION
  name     = "${var.PREFIX}-win-vm"

  # referring child module output variables as an input in root module
  network_interface_ids         = [azurerm_network_interface.winnic.id]
  resource_group_name           = module.resgrp.rgrp["winvmrg"].name
  vm_size                       = "Standard_DS2_v2"
  delete_os_disk_on_termination = true
  tags                          = var.TAGS

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.win-sa.primary_blob_endpoint
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    create_option     = "FromImage"
    name              = "${var.PREFIX}-win-osdisk"
    caching           = "ReadWrite"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-win-vm"
    admin_username = var.WIN_USERNAME
    admin_password = random_password.pwd.result
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}

resource "azurerm_virtual_machine_extension" "example" {
  name                       = "hostname"
  virtual_machine_id         = azurerm_virtual_machine.winvm.id
  publisher                  = "Microsoft.CPlat.Core"
  type                       = "RunCommandWindows"
  type_handler_version       = "1.1"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    script = tolist(["netsh advfirewall firewall add rule name='ICMP Allow incoming V4 echo request' protocol='icmpv4:8,any' dir=in action=allow"])
  })
  tags = var.TAGS
}

data "azurerm_network_interface" "lx_nic" {
  name                = azurerm_network_interface.lxnic.name
  resource_group_name = module.resgrp.rgrp["lxvmrg"].name
}

data "azurerm_network_interface" "win_nic" {
  name                = azurerm_network_interface.winnic.name
  resource_group_name = module.resgrp.rgrp["winvmrg"].name
}


#
#resource "azurerm_virtual_machine_extension" "example" {
#  name                       = "hostname"
#  virtual_machine_id         = azurerm_virtual_machine.vm.id
#  publisher                  = "Microsoft.Azure.Extensions"
#  type                       = "CustomScript"
#  type_handler_version       = "2.0"
#  auto_upgrade_minor_version = true
#
#  settings = <<SETTINGS
#    {
#        "commandToExecute": "sudo apt-get install nginx -y"
#    }
#SETTINGS
#  tags     = var.TAGS
#}
#

