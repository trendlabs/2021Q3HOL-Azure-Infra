locals {
  admin_ip = join("/", [data.http.admin_public_ip.body, "32"])
}
# Dynamically retrieve our public outgoing IP
data "http" "admin_public_ip" {
  url = "http://ipinfo.io/ip"
}

# Create Network Security Group to Access Jump VM from Internet
resource "azurerm_network_security_group" "jump-vm-nsg" {

  count      = length(var.rg_list)
  depends_on = [azurerm_resource_group.rg]

  name                = "${var.environment}-${keys(var.rg_list)[count.index]}-JUMP-nsg-${random_string.random-network-sg[count.index].result}"
  location            = local.resource-groups[count.index].location
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
    source_address_prefixes      = ["94.203.149.240/32","112.211.224.91/32", "175.137.97.232/32",local.admin_ip]
    destination_address_prefix = "*"
  }

  tags = {
    terraform   = "true"
    environment = var.environment
  }
}

# Create Network Security Group to Access web VM from Internet
resource "azurerm_network_security_group" "linux-vm-nsg" {

  count      = length(var.rg_list)
  depends_on = [azurerm_resource_group.rg]

  name                = "${var.environment}-${keys(var.rg_list)[count.index]}-LINUX-nsg-${random_string.random-network-sg[count.index].result}"
  location            = local.resource-groups[count.index].location
  resource_group_name = local.resource-groups[count.index].name

  tags = {
    terraform   = "true"
    environment = var.environment
  }
}
