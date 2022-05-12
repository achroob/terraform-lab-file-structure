resource "azurerm_virtual_network_peering" "vnet-peer1" {
  name                      = "${split("-", var.MOD_RG1_NAME)[1]}to${split("-", var.MOD_RG2_NAME)[1]}"
  remote_virtual_network_id = var.MOD_VNET2_ID
  resource_group_name       = var.MOD_RG1_NAME
  virtual_network_name      = var.MOD_VNET1_NAME
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "vnet-peer2" {
  name                      = "${split("-", var.MOD_RG2_NAME)[1]}to${split("-", var.MOD_RG1_NAME)[1]}"
  remote_virtual_network_id = var.MOD_VNET1_ID
  resource_group_name       = var.MOD_RG2_NAME
  virtual_network_name      = var.MOD_VNET2_NAME
  allow_forwarded_traffic   = true
}
