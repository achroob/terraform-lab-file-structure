output "fw_pub_ip" {
  value = module.firewall.fw_pubip_ip
}

output "lx_pvt_ip" {
  value = data.azurerm_network_interface.lx_nic.private_ip_address
}

output "win_pvt_ip" {
  value = data.azurerm_network_interface.win_nic.private_ip_address
}

output "lx-user-name" {
  value = var.LX_USERNAME
}

output "win-user-name" {
  value = var.WIN_USERNAME
}

output "win-pub-ip" {
  value = azurerm_public_ip.win-pubip.ip_address
}