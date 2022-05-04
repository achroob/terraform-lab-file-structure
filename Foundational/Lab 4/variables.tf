variable "PREFIX" {}

variable "RG_NAME" {
  type = map(string)
}
variable "RG_LOCATION" {}

variable "VNET_ADDRESS" {}
variable "VNET_SUBNET_ADDRESS" {
  type = list(string)
}

variable "FW_VNET_ADDRESS" {}

variable "FW_VNET_SUBNET_ADDRESS" {}

variable "USERNAME" {}
variable "PASSWORD" {
  description = "Enter password for vm"
}

variable "STORAGE_ACCOUNT" {
  type = list(any)
}
variable "STORAGE_CONTAINER" {
}

variable "TAGS" {
  type = map(any)
}