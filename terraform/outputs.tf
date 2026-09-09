output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "web_scale_set_id" {
  value = module.compute.web_scale_set_id
}

output "monitoring_public_ip" {
  description = "Use this to reach Grafana once it's configured"
  value       = module.monitoring.monitoring_public_ip
}
