# create rgs for linux vm, win vm and central in one go
module "resgrp" {
  source          = "./modules/resource_groups"
  MOD_PREFIX      = var.PREFIX
  MOD_RG_LOCATION = var.RG_LOCATION
  MOD_RG_NAME     = var.RG_NAME
  MOD_TAGS        = var.TAGS
}
#create keyvault
module "kv" {
  source          = "./modules/azure_key_vault"
  MOD_KV_NAME     = "${var.PREFIX}-keyva"
  MOD_RG_LOCATION = var.RG_LOCATION
  MOD_RG_NAME     = module.resgrp.rgrp["lxvmrg"].name
}
#Create random password for Window
resource "random_password" "winpwd" {
  length      = 12
  special     = false
  min_lower   = 1
  min_numeric = 3
  min_upper   = 1
}
#Store Window Random password
resource "azurerm_key_vault_secret" "winsecret" {
  key_vault_id = module.kv.kv-id
  name         = "winsecret"
  value        = random_password.winpwd.result
  tags         = var.TAGS
}
#Create random password for Linux
resource "random_password" "lxpwd" {
  length      = 12
  special     = false
  min_lower   = 1
  min_numeric = 3
  min_upper   = 1
}
#Store Linux Random password
resource "azurerm_key_vault_secret" "lxsecret" {
  key_vault_id = module.kv.kv-id
  name         = "lxsecret"
  value        = random_password.lxpwd.result
  tags         = var.TAGS
}
#resource "azurerm_key_vault_key" "sshkey" {
#  key_vault_id = module.kv.kv-id
#  name         = "sshkey"
#  key_type     = "RSA"
#  key_size     = 2048
#
#  key_opts = [
#    "decrypt",
#    "encrypt",
#    "sign",
#    "unwrapKey",
#    "verify",
#    "wrapKey",
#  ]
#}
# create vnet for firewall and bastion host
module "FwNetwork" {
  source           = "./modules/internal_central_hub"
  MOD_RG_LOCATION  = var.RG_LOCATION
  MOD_RG_NAME      = module.resgrp.rgrp["cenrg"].name
  MOD_TAGS         = var.TAGS
  MOD_VNET_ADDRESS = var.FW_VNET_ADDRESS
  MOD_VNET_NAME    = "Central-Hub-vNet"
}
#create bastion subnet
resource "azurerm_subnet" "bastionsub" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = module.resgrp.rgrp["cenrg"].name
  virtual_network_name = module.FwNetwork.nw-name
  address_prefixes     = var.BASITON_SUBNET_ADDRESS
}
#create bastion public ip
resource "azurerm_public_ip" "bastionpubip" {
  allocation_method   = "Static"
  location            = var.RG_LOCATION
  name                = "BastionPubIP"
  resource_group_name = module.resgrp.rgrp["cenrg"].name
  sku                 = "Standard"
}
#create bastion host
resource "azurerm_bastion_host" "bastionhost" {
  location            = var.RG_LOCATION
  name                = "Bastion"
  resource_group_name = module.resgrp.rgrp["cenrg"].name

  ip_configuration {
    name                 = "configuration"
    public_ip_address_id = azurerm_public_ip.bastionpubip.id
    subnet_id            = azurerm_subnet.bastionsub.id
  }
}
#create firewall subnet
resource "azurerm_subnet" "fwsub" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = module.resgrp.rgrp["cenrg"].name
  virtual_network_name = module.FwNetwork.nw-name
  address_prefixes     = var.FW_VNET_SUBNET_ADDRESS
}
#create firewall, firewall pubip, fw policy
module "firewall" {
  source             = "./modules/azure_firewall"
  MOD_RG_LOCATION    = var.RG_LOCATION
  MOD_RG_NAME        = module.resgrp.rgrp["cenrg"].name
  MOD_TAGS           = var.TAGS
  MOD_VNET_NAME      = module.FwNetwork.nw-name
  MOD_VNET_SUBNET_ID = azurerm_subnet.fwsub.id
}
# create virtual network for linux vm
module "LxNetwork" {
  source = "./modules/linux_virtual_network"
  #  Passing variables to child module from root module
  MOD_VNET_NAME    = "Spoke-1-vNet"
  MOD_VNET_ADDRESS = var.LX_VNET_ADDRESS
  MOD_RG_LOCATION  = var.RG_LOCATION
  MOD_RG_NAME      = module.resgrp.rgrp["lxvmrg"].name
  MOD_TAGS         = var.TAGS
}
# create linux subnet
resource "azurerm_subnet" "lxsub" {
  name                 = "sub1"
  resource_group_name  = module.resgrp.rgrp["lxvmrg"].name
  virtual_network_name = module.LxNetwork.nw-name
  address_prefixes     = var.LX_VNET_SUBNET_ADDRESS
}
# create route for linux
module "lxroute" {
  source          = "./modules/azure_route_table"
  MOD_RG_LOCATION = var.RG_LOCATION
  MOD_RG_NAME     = module.resgrp.rgrp["lxvmrg"].name
  MOD_TAGS        = var.TAGS
  MOD_ADD_PREFIX  = "0.0.0.0/0"
  MOD_NXT_HOP_IP  = module.firewall.fw_pvt_ip #Firewall private ip
  MOD_ROUTE_NAME  = "lx-rt"
}
#create nic for virtual network, we will attach it to vm later on
resource "azurerm_network_interface" "lxnic" {
  location            = var.RG_LOCATION
  name                = "lx-nic"
  resource_group_name = module.resgrp.rgrp["lxvmrg"].name

  ip_configuration {
    name                          = "ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.lxsub.id
  }
}
# create generic nsg, otherwise you will not have any access
resource "azurerm_network_security_group" "lxnsg" {
  location            = var.RG_LOCATION
  name                = "lx-nsg"
  resource_group_name = module.resgrp.rgrp["lxvmrg"].name
}
# Associate Linux nsg with subnet
resource "azurerm_subnet_network_security_group_association" "lxsubnsg" {
  network_security_group_id = azurerm_network_security_group.lxnsg.id
  subnet_id                 = azurerm_subnet.lxsub.id
}
# create route with subnet
resource "azurerm_subnet_route_table_association" "lxroute-sub" {
  route_table_id = module.lxroute.rt-id
  subnet_id      = azurerm_subnet.lxsub.id
}
# create virtual network for Window vm
module "WinNetwork" {
  source = "./modules/linux_virtual_network"
  #  Passing variables to child module from root module
  MOD_VNET_NAME    = "Spoke-2-vNet"
  MOD_VNET_ADDRESS = var.WIN_VNET_ADDRESS
  MOD_RG_LOCATION  = var.RG_LOCATION
  MOD_RG_NAME      = module.resgrp.rgrp["winvmrg"].name
  MOD_TAGS         = var.TAGS
}
#create window subnet
resource "azurerm_subnet" "winsub" {
  name                 = "sub1"
  resource_group_name  = module.resgrp.rgrp["winvmrg"].name
  virtual_network_name = module.WinNetwork.nw-name
  address_prefixes     = var.WIN_VNET_SUBNET_ADDRESS
}
#Create window route
module "winroute" {
  source          = "./modules/azure_route_table"
  MOD_RG_LOCATION = var.RG_LOCATION
  MOD_RG_NAME     = module.resgrp.rgrp["winvmrg"].name
  MOD_TAGS        = var.TAGS
  MOD_ADD_PREFIX  = "0.0.0.0/0"
  MOD_NXT_HOP_IP  = module.firewall.fw_pvt_ip #Firewall public ip should come here
  MOD_ROUTE_NAME  = "win-rt"
}
# Associate Route with subnet
resource "azurerm_subnet_route_table_association" "winroute-sub" {
  route_table_id = module.winroute.rt-id
  subnet_id      = azurerm_subnet.winsub.id
}
#create nic for virtual network, we will attach it to vm later on
resource "azurerm_network_interface" "winnic" {
  location            = var.RG_LOCATION
  name                = "win-nic"
  resource_group_name = module.resgrp.rgrp["winvmrg"].name

  ip_configuration {
    name                          = "ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.winsub.id
  }
}
# create generic nsg, otherwise you will not have any access. Rules are not specified because
# communication is allowed between virtual networks
resource "azurerm_network_security_group" "winnsg" {
  location            = var.RG_LOCATION
  name                = "win-nsg"
  resource_group_name = module.resgrp.rgrp["winvmrg"].name
}
# Associate Win nsg with subnet
resource "azurerm_subnet_network_security_group_association" "winsubnsg" {
  network_security_group_id = azurerm_network_security_group.winnsg.id
  subnet_id                 = azurerm_subnet.winsub.id
}
# create peering connection between Linux Virtual network for vm and Network for Firewall
module "lx-vnet-peering" {
  source         = "./modules/virtual_network_peering"
  MOD_RG1_NAME   = module.resgrp.rgrp["lxvmrg"].name
  MOD_VNET1_ID   = module.LxNetwork.nw-id
  MOD_VNET1_NAME = module.LxNetwork.nw-name
  MOD_RG2_NAME   = module.resgrp.rgrp["cenrg"].name
  MOD_VNET2_ID   = module.FwNetwork.nw-id
  MOD_VNET2_NAME = module.FwNetwork.nw-name
  MOD_PEER1_NAME = "lxtofw"
  MOD_PEER2_NAME = "fwtolx"
}
# create peering connection between Win Virtual network for vm and Network for Firewall
module "win-vnet-peering" {
  source         = "./modules/virtual_network_peering"
  MOD_RG1_NAME   = module.resgrp.rgrp["winvmrg"].name
  MOD_VNET1_ID   = module.WinNetwork.nw-id
  MOD_VNET1_NAME = module.WinNetwork.nw-name
  MOD_RG2_NAME   = module.resgrp.rgrp["cenrg"].name
  MOD_VNET2_ID   = module.FwNetwork.nw-id
  MOD_VNET2_NAME = module.FwNetwork.nw-name
  MOD_PEER1_NAME = "wintofw"
  MOD_PEER2_NAME = "fwtowin"
}
#
# create peering connection between Win Virtual network for vm and Linux Virtual Network
module "win-lx-vnet-peering" {
  source         = "./modules/virtual_network_peering"
  MOD_RG1_NAME   = module.resgrp.rgrp["winvmrg"].name
  MOD_VNET1_ID   = module.WinNetwork.nw-id
  MOD_VNET1_NAME = module.WinNetwork.nw-name
  MOD_RG2_NAME   = module.resgrp.rgrp["lxvmrg"].name
  MOD_VNET2_ID   = module.LxNetwork.nw-id
  MOD_VNET2_NAME = module.LxNetwork.nw-name
  MOD_PEER1_NAME = "wintolx"
  MOD_PEER2_NAME = "lxtowin"
}
#create firewall policy to connect to linux/Window machine using publicip of firewall for INBOUND traffic
resource "azurerm_firewall_policy_rule_collection_group" "fw-inbound-rcg" {
  firewall_policy_id = module.firewall.fw_policy_id
  name               = "fw-inbound-rcg"
  priority           = 100
  depends_on         = [module.firewall.fw_name]

  nat_rule_collection {
    action   = "Dnat"
    name     = "AllowSSH"
    priority = 100
    rule {
      name                = "fw-ssh-vm"
      source_addresses    = ["*"]
      protocols           = ["TCP"]
      destination_address = module.firewall.fw_pubip_ip
      destination_ports   = ["22"]
      translated_address  = azurerm_network_interface.lxnic.private_ip_address
      translated_port     = "22"
    }
  }

  nat_rule_collection {
    action   = "Dnat"
    name     = "AllowRDP"
    priority = 200
    rule {
      name                = "fw-rdp-vm"
      source_addresses    = ["*"]
      protocols           = ["TCP"]
      destination_address = module.firewall.fw_pubip_ip
      destination_ports   = ["3389"]
      translated_address  = azurerm_network_interface.winnic.private_ip_address
      translated_port     = "3389"
    }
  }
}
#create firewall rcg for linux and window machine for OUTBOUND traffic
resource "azurerm_firewall_policy_rule_collection_group" "fw-outbound-rcg" {
  firewall_policy_id = module.firewall.fw_policy_id
  name               = "fw-outbound-rcg"
  priority           = 200

  network_rule_collection {
    action   = "Allow"
    name     = "allow_network_rule_linux"
    priority = 100

    rule {
      destination_ports     = ["*"]
      destination_addresses = ["*"]
      name                  = "LinuxTrafficAll"
      protocols             = ["Any"]
      source_addresses      = var.LX_VNET_SUBNET_ADDRESS
    }
  }

  network_rule_collection {
    action   = "Allow"
    name     = "allow_network_rule_windows"
    priority = 200

    rule {
      destination_ports     = ["*"]
      destination_addresses = ["*"]
      name                  = "WindowTrafficAll"
      protocols             = ["Any"]
      source_addresses      = var.WIN_VNET_SUBNET_ADDRESS
    }
  }
}
#create random number
resource "random_id" "random" {
  byte_length = 2
}
#create storage account for window boot diagnostics
module "winsa" {
  source           = "./modules/azure_storage"
  MOD_RG_LOCATION  = var.RG_LOCATION
  MOD_RG_NAME      = module.resgrp.rgrp["winvmrg"].name
  MOD_STORAGE_NAME = "${var.STORAGE_ACCOUNT["winvmrg"]}${random_id.random.hex}"
  TAGS             = var.TAGS
}
#create storage account for linux boot diagnostics
module "lxsa" {
  source           = "./modules/azure_storage"
  MOD_RG_LOCATION  = var.RG_LOCATION
  MOD_RG_NAME      = module.resgrp.rgrp["lxvmrg"].name
  MOD_STORAGE_NAME = "${var.STORAGE_ACCOUNT["lxvmrg"]}${random_id.random.hex}"
  TAGS             = var.TAGS
}
#create linux vm
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
    storage_uri = module.lxsa.primary_blob_endpoint
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
    admin_password = azurerm_key_vault_secret.lxsecret.value
  }

  os_profile_linux_config {
    disable_password_authentication = false

    #    ssh_keys {
    #      key_data = file(azurerm_key_vault_key.sshkey.name)
    #      path     = "/home/${var.LX_USERNAME}/.ssh/authorized_keys"
    #    }
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
    storage_uri = module.winsa.primary_blob_endpoint
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
    admin_password = azurerm_key_vault_secret.winsecret.value
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
    script = tolist(["netsh advfirewall firewall add rule name='ICMP Allow incoming V4 echo request' protocol='icmpv4:8,any' dir=in action=allow",
      "netsh advfirewall firewall add rule name='ICMP Allow incoming V6 echo request' protocol='icmpv6:8,any' dir=in action=allow",
      "netsh advfirewall firewall add rule name='ICMP Allow outgoing V4 echo request' protocol='icmpv4:8,any' dir=out action=allow",
    "netsh advfirewall firewall add rule name='ICMP Allow outgoing V6 echo request' protocol='icmpv6:8,any' dir=out action=allow", ])
  })
  tags = var.TAGS
}

