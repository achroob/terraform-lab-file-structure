resource "azurerm_route_table" "route" {
  location                      = var.MOD_RG_LOCATION
  name                          = var.MOD_ROUTE_NAME
  resource_group_name           = var.MOD_RG_NAME
  tags                          = var.MOD_TAGS
  disable_bgp_route_propagation = false

  route {
    name                   = "route1"
    address_prefix         = var.MOD_ADD_PREFIX
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.MOD_NXT_HOP_IP
  }
}

output "rt-id" {
  value = azurerm_route_table.route.id
}