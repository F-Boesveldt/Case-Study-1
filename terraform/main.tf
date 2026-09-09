resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  project_name         = var.project_name
}

module "compute" {
  source = "./modules/compute"

  resource_group_name  = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  project_name          = var.project_name
  web_subnet_id         = module.network.web_subnet_id
  admin_ssh_public_key  = var.admin_ssh_public_key
}

module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name    = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  project_name            = var.project_name
  monitoring_subnet_id    = module.network.monitoring_subnet_id
  admin_ssh_public_key    = var.admin_ssh_public_key
}
