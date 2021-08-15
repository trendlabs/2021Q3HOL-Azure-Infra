# Create Network Card for CentOS VM

resource "azurerm_network_interface" "centos-vm-nic" {

  name = "${var.prefix}-VNIC-CentOS-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource-group-name

  ip_configuration {
    name                          = "${var.prefix}-centos-internal-${var.suffix}"
    subnet_id                     = var.linux-subnet-id
    private_ip_address_allocation = "Dynamic"
  }
  timeouts {
    create = "10m"
  }
  tags = {
    terraform = "true"
    environment = var.environment
  }
}

# Create Network Card for DVWA VM

resource "azurerm_network_interface" "dvwa-vm-nic" {

  name = "${var.prefix}-VNIC-DVWA-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource-group-name

  ip_configuration {
    name                          = "${var.prefix}-dvwa-internal-${var.suffix}"
    subnet_id                     = var.linux-subnet-id
    private_ip_address_allocation = "Dynamic"
  }
  timeouts {
    create = "10m"
  }
  tags = {
    terraform = "true"
    environment = var.environment
  }
}

# Get a Static Public IP for Jump VM
resource "azurerm_public_ip" "jump-public-ip" {

  name = "${var.prefix}-Jump-pubIP-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource-group-name
  allocation_method   = "Static"

  tags = {
    terraform = "true"
    environment = var.environment
  }
}

# Create Network Card for Jump VM
resource "azurerm_network_interface" "jump-vm-nic" {

  name = "${var.prefix}-VNIC-JUMP-${var.suffix}"
  location = var.location
  resource_group_name = var.resource-group-name

  ip_configuration {
    name = "${var.prefix}-jump-internal-${var.suffix}"
    subnet_id = var.jump-subnet-id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.jump-public-ip.id
  }
  timeouts {
    create = "10m"
  }
  tags = {
    terraform = "true"
    environment = var.environment
  }
}

# Create Network Card for KALI VM

resource "azurerm_network_interface" "kali-vm-nic" {

  name = "${var.prefix}-VNIC-KALI-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource-group-name

  ip_configuration {
    name                          = "${var.prefix}-kali-internal-${var.suffix}"
    subnet_id                     = var.jump-subnet-id
    private_ip_address_allocation = "Dynamic"
  }

  timeouts {
    create = "10m"
  }

  tags = {
    terraform = "true"
    environment = var.environment
  }
}
