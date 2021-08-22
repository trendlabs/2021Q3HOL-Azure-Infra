
# Data template Bash bootstrapping file
data "template_file" "centos-vm-cloud-init" {
  count = var.num-of-labs
  template = templatefile("${path.module}/data/centos.sh", {
    ADMIN-USER     = var.admin-username,
    ADMIN-PASSWORD = var.admin-password,
    PRIV-KEY       = tls_private_key.private-key.private_key_pem,
    KALI-PRIV-IP   = module.labvNic[count.index].kali-vnic.ip,
    CENTOS-PRIV-IP = module.labvNic[count.index].centos-vnic.ip,
    DVWA-PRIV-IP   = module.labvNic[count.index].dvwa-vnic.ip,
    JUMP-PRIV-IP   = module.labvNic[count.index].jump-vnic.priv-ip,
    JUMP-PUB-IP    = module.labvNic[count.index].jump-vnic.pub-ip
  })
}

# Create CentOS VM
resource "azurerm_linux_virtual_machine" "centos-vm" {
  count = var.num-of-labs

  name                  = "${local.prefix}-VM-CentOS-${count.index + 1}-${random_string.random-lab-vm[count.index].result}"
  location              = local.location
  resource_group_name   = var.resource-group-name
  network_interface_ids = [module.labvNic[count.index].centos-vnic.id]
  size                  = var.linux.vm-size

  priority        = var.spot-vm.priority
  max_bid_price   = var.spot-vm.max-bid-price
  eviction_policy = "Deallocate"

  source_image_reference {
    offer     = var.linux.vm-image.offer
    publisher = var.linux.vm-image.publisher
    sku       = var.linux.vm-image.sku
    version   = var.linux.vm-image.version
  }

  os_disk {
    name                 = "${local.prefix}-OSDISK-CentOS-${count.index + 1}-${random_string.random-lab-vm[count.index].result}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = var.admin-username
    public_key = tls_private_key.private-key.public_key_openssh
  }
  # disable_password_authentication = true
  custom_data                     = base64encode(data.template_file.centos-vm-cloud-init[count.index].rendered)
  computer_name                   = "CentOS-${count.index + 1}"
  admin_username                  = var.admin-username
  # admin_password                  = var.admin-password

  tags = {
    terraform   = "true"
    environment = var.environment
  }
}

# wait for dvwa ready
resource "time_sleep" "wait-for-centos-vm" {

  create_duration = "3m"

  depends_on = [azurerm_linux_virtual_machine.centos-vm]
}
