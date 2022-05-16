PREFIX = "demo"

RG_NAME = {
  lxvmrg  = "rg-lab-training"
  winvmrg = "rg-lab-training-02"
  cenrg   = "rg-central-hub"
}
RG_LOCATION = "northeurope"

FW_VNET_ADDRESS        = "10.3.0.0/16"
FW_VNET_SUBNET_ADDRESS = ["10.3.1.0/24"]

LX_VNET_ADDRESS        = "10.0.0.0/16"
LX_VNET_SUBNET_ADDRESS = ["10.0.2.0/24"]

WIN_VNET_ADDRESS        = "10.1.0.0/16"
WIN_VNET_SUBNET_ADDRESS = ["10.1.0.0/24"]

BASITON_SUBNET_ADDRESS = ["10.3.0.0/24"]

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
