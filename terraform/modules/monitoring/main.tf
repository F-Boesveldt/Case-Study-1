# Monitoring VM: Prometheus + Grafana. Skeleton for Week 1 — the actual
# Prometheus config (azure_sd_config for auto-discovery, exporter scrape
# targets, Alertmanager webhook) is Week 3 work per the Design Document.

resource "azurerm_public_ip" "monitoring" {
  name                = "${var.project_name}-monitoring-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "monitoring" {
  name                = "${var.project_name}-monitoring-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "monitoring-ipconfig"
    subnet_id                     = var.monitoring_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.monitoring.id
  }
}

resource "azurerm_linux_virtual_machine" "monitoring" {
  name                = "${var.project_name}-monitoring-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B2s"
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.monitoring.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching               = "ReadWrite"
  }

  # TODO Week 3: custom_data with cloud-init to install Prometheus, Grafana,
  # and Alertmanager, plus the azure_sd_config scrape configuration.
}
