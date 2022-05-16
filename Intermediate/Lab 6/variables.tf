variable "PREFIX" {}

variable "RG_NAME" {
  type = map(string)
}
variable "RG_LOCATION" {}

variable "LX_VNET_ADDRESS" {}
variable "LX_VNET_SUBNET_ADDRESS" {
  type = list(string)
}

variable "WIN_VNET_ADDRESS" {}
variable "WIN_VNET_SUBNET_ADDRESS" {
  type = list(string)
}

variable "FW_VNET_ADDRESS" {}
variable "FW_VNET_SUBNET_ADDRESS" {
  type = list(string)
}

variable "LX_USERNAME" {}
variable "WIN_USERNAME" {}
variable "PASSWORD" {
  description = "Enter password for vm"
}

variable "STORAGE_ACCOUNT" {
  type = map(string)
}

variable "TAGS" {
  type = map(any)
}

variable "BASITON_SUBNET_ADDRESS" {}
