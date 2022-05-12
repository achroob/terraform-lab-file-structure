PREFIX = "demo"

RG_NAME = {
  lxvmrg  = "lx-rg"
  winvmrg = "win-rg"
  fwrg    = "fw-rg"
}
RG_LOCATION = "northeurope"

FW_VNET_ADDRESS        = "10.0.0.0/16"
FW_VNET_SUBNET_ADDRESS = ["10.0.1.0/24"]

LX_VNET_ADDRESS        = "10.1.0.0/16"
LX_VNET_SUBNET_ADDRESS = ["10.1.0.0/24"]

WIN_VNET_ADDRESS        = "10.2.0.0/16"
WIN_VNET_SUBNET_ADDRESS = ["10.2.0.0/24"]

LX_USERNAME  = "linuxusr"
WIN_USERNAME = "winuser"
PASSWORD     = "Administrator@890"

STORAGE_ACCOUNT = {
  lxvmrg  = "lxbootdiag"
  winvmrg = "winbootdiag"
}

TAGS = {
  "Name"       = "DemoProject"
  "CostCentre" = "MyCompany"
}
