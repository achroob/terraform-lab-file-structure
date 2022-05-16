resource "azurerm_virtual_network" "vnet" {
  name                = var.MOD_VNET_NAME
  address_space       = [var.MOD_VNET_ADDRESS]
  location            = var.MOD_RG_LOCATION
  resource_group_name = var.MOD_RG_NAME
  tags                = var.MOD_TAGS
}

output "nw-id" {
  value = azurerm_virtual_network.vnet.id
}

output "nw-name" {
  value = azurerm_virtual_network.vnet.name
}
