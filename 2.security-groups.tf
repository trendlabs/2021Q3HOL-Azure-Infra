# Create Network Security Group to Access Jump VM from Internet
resource "azurerm_network_security_group" "jump-vm-nsg" {

  count = length(var.rg_list)

  name                = "${var.environment}-${local.resource-groups[count.index].name}-JUMP-nsg-${random_string.random-network-sg[count.index].result}"
  location            = local.location[count.index]
  resource_group_name = local.resource-groups[count.index].name

  //allow RDP from internet
  security_rule {
    name                       = "allow-rdp-to-jump"
    description                = "allow-rdp-to-jump"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  //allow All from vNet subnets to Jump
  security_rule {
    name                       = "allow-all-internal-to-jump"
    description                = "Allow all traffic from vNet Subnets"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.network-vnet-cidr
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
  }
}

# Create Network Security Group to Access web VM from Internet
resource "azurerm_network_security_group" "linux-vm-nsg" {

  count = length(var.rg_list)

  name                = "${var.environment}-${local.resource-groups[count.index].name}-LINUX-nsg-${random_string.random-network-sg[count.index].result}"
  location            = local.location[count.index]
  resource_group_name = local.resource-groups[count.index].name

  //allow all from vnet
  security_rule {
    name                       = "allow-all-internal-traffic-"
    description                = "All all internal traffic originated within vNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.network-vnet-cidr
    destination_address_prefix = "*"
  }
  tags = {
    environment = var.environment
  }
}
