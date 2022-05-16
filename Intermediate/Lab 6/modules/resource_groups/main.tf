resource "azurerm_resource_group" "resgrp" {
  location = var.MOD_RG_LOCATION
  name     = each.value #unique name will be picked
  tags     = var.MOD_TAGS
  for_each = var.MOD_RG_NAME # Looping to create multiple resource groups, based on value specified in set variable
}

# Returning map variable is difficult, so returning whole object
output "rgrp" {
  value = azurerm_resource_group.resgrp
}
