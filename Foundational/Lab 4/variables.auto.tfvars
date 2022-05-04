PREFIX = "demo"

RG_NAME = {
  vmrg = "rg"
  fwrg = "fw-rg"
}
RG_LOCATION = "northeurope"

VNET_ADDRESS = "10.1.0.0/16"

VNET_SUBNET_ADDRESS = ["10.1.0.0/24", "10.1.1.0/24"]

FW_VNET_ADDRESS        = "10.2.0.0/16"
FW_VNET_SUBNET_ADDRESS = "10.2.0.0/24"

USERNAME = "linuxusr"
PASSWORD = "Administrator@890"

STORAGE_ACCOUNT   = ["bootdiagonistic", "tfstatebackend"]
STORAGE_CONTAINER = "tfstate"

TAGS = {
  "Name"       = "DemoProject"
  "CostCentre" = "MyCompany"
}