terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

terraform {
  backend "azurerm" {
    resource_group_name  = "demo-state-rg"
    storage_account_name = "demotfstatebackend"
    container_name       = "lab6"
    key                  = "terraform.tfstate"
  }
}
