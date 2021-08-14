
# Create the network VNET
resource "azurerm_virtual_network" "network-vnet" {
  count               = length(var.rg_list)
  name                = "${var.environment}-${local.resource-groups[count.index].name}-VNET-${random_string.random-network-sg[count.index].result}"
  address_space       = [var.network-vnet-cidr]
  resource_group_name = local.resource-groups[count.index].name
  location            = local.location[count.index]
  tags = {
    environment = var.environment
  }
}

# Create a subnet for Jump VM
resource "azurerm_subnet" "jump-subnet" {
  count                = length(var.rg_list)
  name                 = "${var.environment}-${local.resource-groups[count.index].name}-JUMP-subnet-${random_string.random-network-sg[count.index].result}"
  address_prefixes     = [var.jump-subnet-cidr]
  virtual_network_name = azurerm_virtual_network.network-vnet[count.index].name
  resource_group_name  = local.resource-groups[count.index].name
}

resource "azurerm_subnet_network_security_group_association" "jump-subnet-sg" {

  count = length(var.rg_list)

  subnet_id                 = azurerm_subnet.jump-subnet[count.index].id
  network_security_group_id = azurerm_network_security_group.jump-vm-nsg[count.index].id

}

# Create a subnet for Linux VMs
resource "azurerm_subnet" "linux-subnet" {
  count                = length(var.rg_list)
  name                 = "${var.environment}-${local.resource-groups[count.index].name}-LINUX-subnet-${random_string.random-network-sg[count.index].result}"
  address_prefixes     = [var.linux-subnet-cidr]
  virtual_network_name = azurerm_virtual_network.network-vnet[count.index].name
  resource_group_name  = local.resource-groups[count.index].name
}

resource "azurerm_subnet_network_security_group_association" "linux-subnet-sg" {

  count = length(var.rg_list)

  subnet_id                 = azurerm_subnet.linux-subnet[count.index].id
  network_security_group_id = azurerm_network_security_group.linux-vm-nsg[count.index].id

}
