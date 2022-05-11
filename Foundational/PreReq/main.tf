resource "azurerm_resource_group" "resgrp" {
  location = var.RG_LOCATION
  name     = "${var.PREFIX}-rg"
}

terraform {
  backend "azurerm" {
    resource_group_name  = azurerm_resource_group.resgrp.name
    storage_account_name = azurerm_storage_account.sa[1].name
    container_name       = azurerm_storage_container.sc.name
    key                  = "terraform.tfstate"
  }
}

resource "random_id" "random" {
  byte_length = 2
}

resource "azurerm_storage_account" "sa" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.RG_LOCATION
  name                     = "${var.STORAGE_ACCOUNT[count.index]}${random_id.random.hex}"
  resource_group_name      = azurerm_resource_group.resgrp.name
  count                    = length(var.STORAGE_ACCOUNT)
}

resource "azurerm_storage_container" "sc" {
  name                 = "tfstate"
  storage_account_name = azurerm_storage_account.sa[1].name
}