locals {
  location = data.azurerm_resource_group.lab-rg.location
  prefix   = format("%s-%s", var.environment, replace(var.resource-group-name, "${var.environment}-", ""))
}

// Get resource group data
data "azurerm_resource_group" "lab-rg" {
  name = var.resource-group-name
}

data "azurerm_virtual_network" "lab-vnet" {

  name                = var.virtual-network-name
  resource_group_name = var.resource-group-name
}

data "azurerm_subnet" "jump-subnet" {

  count = var.num-of-labs

  name                 = var.jump.subnet-name
  virtual_network_name = data.azurerm_virtual_network.lab-vnet.name
  resource_group_name  = var.resource-group-name
}

data "azurerm_subnet" "linux-subnet" {

  name                 = var.linux.subnet-name
  virtual_network_name = data.azurerm_virtual_network.lab-vnet.name
  resource_group_name  = var.resource-group-name
}

# Generate randon name for virtual machine
resource "random_string" "random-lab-vm" {

  count = var.num-of-labs

  length  = 8
  special = false
  lower   = true
  upper   = false
  number  = true
}

resource "tls_private_key" "private-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "labvNic" {

  count  = var.num-of-labs
  source = "./labvNicset"

  environment         = var.environment
  resource-group-name = var.resource-group-name
  location            = local.location

  jump-subnet-id  = var.jump.subnet-id
  linux-subnet-id = var.linux.subnet-id

  prefix = local.prefix
  suffix = "${count.index + 1}-${random_string.random-lab-vm[count.index].result}"

}
