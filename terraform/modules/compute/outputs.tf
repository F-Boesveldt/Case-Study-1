output "web_scale_set_id" {
  value = azurerm_linux_virtual_machine_scale_set.web.id
}

output "web_public_ip" {
  value = azurerm_public_ip.web.ip_address
}
