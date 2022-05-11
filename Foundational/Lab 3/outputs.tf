output "public_ip_address" {
  value = data.azurerm_public_ip.datapubip.ip_address
}

output "username" {
  value = var.USERNAME
}