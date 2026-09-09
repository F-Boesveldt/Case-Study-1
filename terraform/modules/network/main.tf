# Hub-and-spoke network module.
# Matches the design in the Design Document: Hub (firewall + DoH resolver),
# Web spoke, DB spoke (web-tier-only access), Monitoring subnet (routed
# through the hub via UDR rather than peered directly).

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "hub" {
  name                 = "hub-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "web" {
  name                 = "web-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  # Required for Azure Database for MySQL Flexible Server (private access)
  delegation {
    name = "mysql-delegation"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "monitoring" {
  name                 = "monitoring-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
}

# ---- NSGs ----

resource "azurerm_network_security_group" "web" {
  name                = "${var.project_name}-web-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowHTTPFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "db" {
  name                = "${var.project_name}-db-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # REQ-02: DB reachable only from the web subnet, nothing else — not even the hub.
  security_rule {
    name                       = "AllowMySQLFromWebOnly"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = azurerm_subnet.web.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllOtherInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "monitoring" {
  name                = "${var.project_name}-monitoring-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Only the exporter ports, and only from web/db, reach monitoring —
  # even though traffic arrives via the hub, source IPs are preserved.
  security_rule {
    name                       = "AllowExportersFromWebAndDb"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["9100", "9104"]
    source_address_prefixes    = [azurerm_subnet.web.address_prefixes[0], azurerm_subnet.db.address_prefixes[0]]
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}

resource "azurerm_subnet_network_security_group_association" "monitoring" {
  subnet_id                 = azurerm_subnet.monitoring.id
  network_security_group_id = azurerm_network_security_group.monitoring.id
}

# ---- Route tables: force web/db -> monitoring traffic through the hub ----
# This is the UDR piece from the "route monitoring through the hub" decision.
# TODO once the hub firewall/NVA exists: set next_hop_type to
# "VirtualAppliance" with the NVA's private IP instead of "VnetLocal".

resource "azurerm_route_table" "via_hub" {
  name                = "${var.project_name}-via-hub-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "to-monitoring-via-hub"
    address_prefix         = azurerm_subnet.monitoring.address_prefixes[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.4" # TODO: replace with the hub NVA's actual private IP
  }
}

resource "azurerm_subnet_route_table_association" "web" {
  subnet_id      = azurerm_subnet.web.id
  route_table_id = azurerm_route_table.via_hub.id
}

resource "azurerm_subnet_route_table_association" "db" {
  subnet_id      = azurerm_subnet.db.id
  route_table_id = azurerm_route_table.via_hub.id
}
