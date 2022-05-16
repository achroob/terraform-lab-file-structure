output "fw_pub_ip" {
  value = module.firewall.fw_pubip_ip
}

output "lx_pvt_ip" {
  value = azurerm_network_interface.lxnic.private_ip_address
}

output "win_pvt_ip" {
  value = azurerm_network_interface.winnic.private_ip_address
}

output "lx-user-name" {
  value = var.LX_USERNAME
}

output "win-user-name" {
  value = var.WIN_USERNAME
}


