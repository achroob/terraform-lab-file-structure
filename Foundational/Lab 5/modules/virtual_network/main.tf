resource "azurerm_virtual_network" "vnet" {
  name                = var.MOD_VNET_NAME
  address_space       = [var.MOD_VNET_ADDRESS]
  location            = var.MOD_RG_LOCATION
  resource_group_name = var.MOD_RG_NAME
  tags                = var.MOD_TAGS
}


resource "azurerm_subnet" "sub" {
  name                 = length(var.MOD_VNET_SUBNET_NAME) != 0 ? var.MOD_VNET_SUBNET_NAME[count.index] : "sub-${count.index}"
  resource_group_name  = var.MOD_RG_NAME
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.MOD_VNET_SUBNET_ADDRESS[count.index]]
  count                = length(var.MOD_VNET_SUBNET_ADDRESS)
}

output "nw-id" {
  value = azurerm_virtual_network.vnet.id
}

output "nw-name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnet-id" {
  value = azurerm_subnet.sub[*].id
}

output "subnet-name" {
  value = azurerm_subnet.sub[*].name
}
