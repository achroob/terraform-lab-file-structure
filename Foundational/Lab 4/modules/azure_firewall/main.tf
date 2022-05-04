resource "azurerm_subnet" "sub-fw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.MOD_RG_NAME
  virtual_network_name = var.MOD_VNET_NAME
  address_prefixes     = [var.MOD_VNET_SUBNET_ADDRESS]
}

resource "azurerm_public_ip" "pubip" {
  allocation_method   = "Static"
  sku                 = "Standard"
  location            = var.MOD_RG_LOCATION
  name                = "fw-pubip"
  resource_group_name = var.MOD_RG_NAME
  tags                = var.MOD_TAGS
}

resource "azurerm_firewall_policy" "fwpolicy" {
  location            = var.MOD_RG_LOCATION
  name                = "fwpolicy"
  resource_group_name = var.MOD_RG_NAME
  sku                 = "Standard"
}

resource "azurerm_firewall" "fw" {
  location            = var.MOD_RG_LOCATION
  name                = "demo-fw"
  resource_group_name = var.MOD_RG_NAME
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id = azurerm_firewall_policy.fwpolicy.id

  ip_configuration {
    name                 = "config"
    public_ip_address_id = azurerm_public_ip.pubip.id
    subnet_id            = azurerm_subnet.sub-fw.id
  }
}

output "fw_name" {
  value = azurerm_firewall.fw.name
}

output "fw_pubip_name" {
  value = azurerm_public_ip.pubip.name
}

output "fw_pubip_ip" {
  value = azurerm_public_ip.pubip.ip_address
}

output "fw_policy_id" {
  value = azurerm_firewall_policy.fwpolicy.id
}