output "fw_pub_ip" {
  value = data.azurerm_public_ip.fw_pubip.ip_address

}
#
#output "user" {
#  value = ${each.value}.admin_username
#  for_each = azurerm_virtual_machine.vm.os_profile
#}

