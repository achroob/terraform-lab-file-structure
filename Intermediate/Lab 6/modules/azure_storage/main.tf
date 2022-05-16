resource "azurerm_storage_account" "sa" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.MOD_RG_LOCATION
  name                     = var.MOD_STORAGE_NAME
  resource_group_name      = var.MOD_RG_NAME
  tags                     = var.TAGS
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.sa.primary_blob_endpoint
}