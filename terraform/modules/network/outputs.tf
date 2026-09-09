output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "hub_subnet_id" {
  value = azurerm_subnet.hub.id
}

output "web_subnet_id" {
  value = azurerm_subnet.web.id
}

output "db_subnet_id" {
  value = azurerm_subnet.db.id
}

output "monitoring_subnet_id" {
  value = azurerm_subnet.monitoring.id
}
