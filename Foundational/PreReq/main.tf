resource "azurerm_resource_group" "resgrp" {
  location = var.RG_LOCATION
  name     = "${var.PREFIX}-rg"
}

resource "azurerm_storage_account" "sa" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.RG_LOCATION
  name                     = var.STORAGE_ACCOUNT
  resource_group_name      = azurerm_resource_group.resgrp.name
}

resource "azurerm_storage_container" "sc" {
  name                 = var.LAB_NAME[count.index]
  storage_account_name = azurerm_storage_account.sa.name
  count                = length(var.LAB_NAME)
}