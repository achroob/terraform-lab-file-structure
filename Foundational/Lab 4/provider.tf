
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "demo-state-rg"
    storage_account_name = "demotfstatebackend"
    container_name       = "lab4"
    key                  = "terraform.tfstate"
  }
}