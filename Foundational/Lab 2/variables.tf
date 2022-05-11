variable "PREFIX" {
  default = "demo"
}

variable "RG_LOCATION" {
  default = "northeurope"
}

variable "VNET_ADDRESS" {
  default = "10.1.0.0/16"
}

variable "VNET_SUBNET1_ADDRESS" {
  default = "10.1.1.0/24"
}

variable "USERNAME" {
  default = "linuxusr"
}

variable "PASSWORD" {
  sensitive   = true
  description = "Enter password for vm"
  default     = "Admin@890"
}