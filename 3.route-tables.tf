resource "azurerm_route_table" "jump-2-linux" {
  count               = length(var.rg_list)
  depends_on          = [azurerm_resource_group.rg]
  name                = "${var.environment}-${keys(var.rg_list)[count.index]}-J2L-RTB-${random_string.random-network-sg[count.index].result}"
  location            = local.resource-groups[count.index].location
  resource_group_name = local.resource-groups[count.index].name
  //disable_bgp_route_propagation = false

  route {
    name           = "${var.environment}-${keys(var.rg_list)[count.index]}-J2L-ROUTE-${random_string.random-network-sg[count.index].result}"
    address_prefix = var.linux-subnet-cidr
    next_hop_type  = "vnetlocal"
  }
  tags = {
    terraform   = "true"
    environment = var.environment
  }
}

resource "azurerm_subnet_route_table_association" "jump-2-linux" {
  count = length(var.rg_list)

  subnet_id      = azurerm_subnet.jump-subnet[count.index].id
  route_table_id = azurerm_route_table.jump-2-linux[count.index].id
}

resource "azurerm_route_table" "linux-2-jump" {
  count               = length(var.rg_list)
  depends_on          = [azurerm_resource_group.rg]
  name                = "${var.environment}-${keys(var.rg_list)[count.index]}-L2J-RTB-${random_string.random-network-sg[count.index].result}"
  location            = local.resource-groups[count.index].location
  resource_group_name = local.resource-groups[count.index].name
  //disable_bgp_route_propagation = false

  route {
    name           = "${var.environment}-${keys(var.rg_list)[count.index]}-J2L-ROUTE-${random_string.random-network-sg[count.index].result}"
    address_prefix = var.jump-subnet-cidr
    next_hop_type  = "vnetlocal"
  }

  tags = {
    terraform   = "true"
    environment = var.environment
  }
}

resource "azurerm_subnet_route_table_association" "linux-2-jump" {
  count = length(var.rg_list)

  subnet_id      = azurerm_subnet.linux-subnet[count.index].id
  route_table_id = azurerm_route_table.linux-2-jump[count.index].id
}
