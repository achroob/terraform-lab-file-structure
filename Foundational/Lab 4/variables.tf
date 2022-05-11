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

variable "STORAGE_ACCOUNT" {}

variable "TAGS" {
  type = map(any)
}