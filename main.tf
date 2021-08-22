# TF_LOG=DEBUG
# TF_LOG_PATH=/tmp/log

locals {
  //Australia Central: to save cost & near APAC
  // https://azureprice.net/?region=australiacentral&priority=spot
  resource-groups = (var.create-rgs) ? flatten([
    for name in keys(var.rg_list)[*] : {
      name     = "${var.environment}-${name}"
      location = "Australia Central"
    }
    ]) : flatten([
    for data in data.azurerm_resource_group.lab-rg[*] : {
      name     = data.name
      location = data.location
    }
  ])

  //location = (var.create-rgs) ? local.resource-groups[*].location : data.azurerm_resource_group.lab-rg[*].location
}

#Configure the Azure Provider
provider "azurerm" {
  features {}

  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret

}

# Create new resource groups
resource "azurerm_resource_group" "rg" {
  count    = (var.create-rgs) ? length(var.rg_list) : 0
  name     = local.resource-groups[count.index].name
  location = local.resource-groups[count.index].location
  tags = {
    terraform   = "true"
    environment = var.environment
  }
}

# Get resource group data
data "azurerm_resource_group" "lab-rg" {

  count = (var.create-rgs) ? 0 : length(var.rg_list)

  name = keys(var.rg_list)[count.index] //local.resource-groups[count.index].name
}

data "azuread_group" "APAC-HOL-Specialist" {
  display_name     = "APAC-HOL-Specialist"
  security_enabled = true
}

#grant access to rg
resource "azurerm_role_assignment" "rg-grant-access" {
  count = length(var.rg_list)
  scope                = (var.create-rgs) ? azurerm_resource_group.rg[count.index].id : data.azurerm_resource_group.lab-rg[count.index].id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_group.APAC-HOL-Specialist.id
}
#
# #grant access to nsg
resource "azurerm_role_assignment" "nsg-grant-access" {
  count = length(var.rg_list)
  
  scope                = azurerm_network_security_group.jump-vm-nsg[count.index].id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_group.APAC-HOL-Specialist.id
}

# Generate randon name for network resources
resource "random_string" "random-network-sg" {

  count = length(var.rg_list)

  length  = 8
  special = false
  lower   = true
  upper   = false
  number  = true
}

# wait for all subnets ready
resource "time_sleep" "wait-for-subnets" {

  create_duration = "30s"

  depends_on = [
    azurerm_subnet.jump-subnet,
    azurerm_subnet.linux-subnet
  ]
}

# Provision VMs
module "lab-VM-provision" {

  count = length(var.rg_list)

  depends_on = [time_sleep.wait-for-subnets]

  source = "./modules/labVMset"

  environment    = var.environment
  admin-username = var.admin-username
  admin-password = var.admin-password

  install-dvwa = false
  install-dnscat = false

  resource-group-name = local.resource-groups[count.index].name
  num-of-labs         = values(var.rg_list)[count.index]

  virtual-network-name = azurerm_virtual_network.network-vnet[count.index].name

  spot-vm = {
    max-bid-price = "0.3"  // usd0.3 bid price
    priority      = "Spot" // "Regular"
  }

  jump = {
    subnet-id   = azurerm_subnet.jump-subnet[count.index].id
    subnet-name = azurerm_subnet.jump-subnet[count.index].name
    vm-size     = "Standard_D4s_v4"
    # 4vCPU & 16GbRAM & ACU 195
    # Central US Spot Windows price ~$0.19641/hour
    # Australia Central Spot Windows price ~0.069485/hour
    vm-image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
    }

  }

  linux = {
    subnet-id   = azurerm_subnet.linux-subnet[count.index].id
    subnet-name = azurerm_subnet.linux-subnet[count.index].name
    vm-size     = "Standard_D2s_v4"
    # 2vCPU & 8GbRAM & ACU 195
    # Central US Spot CentOS price ~$0.020774/hour
    # Australia Central Spot price ~$0.0139/hour
    vm-image = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "8_4-gen2"
      version   = "latest"
    }
  }

}

data "template_file" "outputs" {
  count = length(var.rg_list)
  template = templatefile("./outputs/outputs.tpl", {
    ADMIN-USER     = var.admin-username,
    ADMIN-PASSWORD = var.admin-password,
    RG-NAME        = local.resource-groups[count.index].name
    RG-LOCATION    = local.resource-groups[count.index].location
    JUMP-IP-LIST   = join("\n", module.lab-VM-provision[count.index].jump_public_ip_address)
    SG-NAME = azurerm_network_security_group.jump-vm-nsg[count.index].name
  })
}

resource "local_file" "outputs" {
  count    = length(var.rg_list)
  content  = data.template_file.outputs[count.index].rendered
  filename = "./outputs/${keys(var.rg_list)[count.index]}.txt"
}
