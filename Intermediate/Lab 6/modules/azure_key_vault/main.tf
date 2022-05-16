data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  location            = var.MOD_RG_LOCATION
  name                = var.MOD_KV_NAME
  resource_group_name = var.MOD_RG_NAME
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enabled_for_disk_encryption = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "baf33b88-f823-405e-b951-aa3c6e407f3b"  #object id for myadmin user (my administrator for portal)

    key_permissions = [
     "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get",
      "Import", "List", "Purge", "Recover", "Restore", "Sign",
      "UnwrapKey", "Update",  "Verify", "WrapKey"
    ]

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]

    storage_permissions = [
      "Get",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id #object id for service principal

    key_permissions = [
      "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get",
      "Import", "List", "Purge", "Recover", "Restore", "Sign",
      "UnwrapKey", "Update",  "Verify", "WrapKey"
    ]

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

output "kv-id" {
  value = azurerm_key_vault.kv.id
}
