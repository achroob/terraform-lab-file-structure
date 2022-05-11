variable "PREFIX" {}

variable "RG_LOCATION" {}

variable "VNET_ADDRESS" {}

variable "VNET_SUBNET_ADDRESS" {}

variable "USERNAME" {}

variable "PASSWORD" {
  sensitive   = true
  description = "Enter password for vm"
}

variable "STORAGE_ACCOUNT" {
  type = list(any)
}

variable "STORAGE_CONTAINER" {
}