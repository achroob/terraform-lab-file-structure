resource "azurerm_virtual_network_peering" "vnet-peer1" {
  name                      = "peer1to2"
  remote_virtual_network_id = var.MOD_VNET2_ID
  resource_group_name       = var.MOD_RG1_NAME
  virtual_network_name      = var.MOD_VNET1_NAME

}

resource "azurerm_virtual_network_peering" "vnet-peer2" {
  name                      = "peer2to1"
  remote_virtual_network_id = var.MOD_VNET1_ID
  resource_group_name       = var.MOD_RG2_NAME
  virtual_network_name      = var.MOD_VNET2_NAME
}