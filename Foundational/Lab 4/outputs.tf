output "fw_pub_ip" {
  value = data.azurerm_public_ip.fw_pubip.ip_address
}

output "username" {
  value = var.USERNAME
}