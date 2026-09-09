# Web tier: VM Scale Set behind a load balancer, autoscaling on CPU.
# This is a skeleton for Week 1 — full config (rolling upgrade policy,
# custom image or cloud-init for Nginx+Docker, autoscale rules) is Week 2 work.

resource "azurerm_lb" "web" {
  name                = "${var.project_name}-web-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "web-frontend"
    public_ip_address_id = azurerm_public_ip.web.id
  }
}

resource "azurerm_public_ip" "web" {
  name                = "${var.project_name}-web-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_linux_virtual_machine_scale_set" "web" {
  name                = "${var.project_name}-web-vmss"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard_B2s"
  instances           = 2 # REQ-04 minimum
  admin_username      = "azureuser"

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
    storage_account_type = "Premium_LRS"
    caching               = "ReadWrite"
  }

  network_interface {
    name    = "web-nic"
    primary = true

    ip_configuration {
      name      = "web-ipconfig"
      primary   = true
      subnet_id = var.web_subnet_id
    }
  }

  # TODO Week 2: custom_data with cloud-init to install Docker + pull the
  # Nginx container, and an upgrade_policy block (rolling) once the
  # deployment strategy is implemented.
}

# TODO Week 2/3: azurerm_monitor_autoscale_setting resource implementing
# the scale-out/scale-in thresholds from the Design Document
# (CPU > 70% for 5min / < 30% for 10min, min 2 / max 6).

# TODO Week 2: azurerm_mysql_flexible_server for the database tier,
# delegated into the db subnet, with the NSG already restricting access
# to the web subnet only (see the network module).
