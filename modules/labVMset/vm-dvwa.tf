

# Data template Bash bootstrapping file
data "template_file" "dvwa-vm-cloud-init" {
  count = var.num-of-labs
  template = templatefile("${path.module}/data/dvwa.sh", {
    ADMIN-PASSWORD = var.admin-password,
    ADMIN-USER = var.admin-username,
    PRIV-KEY = tls_private_key.private-key[count.index].private_key_pem,
    KALI-PRIV-IP = module.labvNic[count.index].kali-vnic.ip,
    CENTOS-PRIV-IP = module.labvNic[count.index].centos-vnic.ip,
    DVWA-PRIV-IP = module.labvNic[count.index].dvwa-vnic.ip,
    JUMP-PRIV-IP = module.labvNic[count.index].jump-vnic.priv-ip
  })
}

# Create DVWA VM
resource "azurerm_linux_virtual_machine" "dvwa-vm" {

  count = var.num-of-labs

  name = "${local.prefix}-VM-DVWA-${count.index+1}-${random_string.random-lab-vm[count.index].result}"
  location              = local.location
  resource_group_name   = var.resource-group-name
  network_interface_ids = [module.labvNic[count.index].dvwa-vnic.id]
  size                  = var.linux.vm-size

  priority = var.spot-vm.priority
  max_bid_price = var.spot-vm.max-bid-price
  eviction_policy = "Deallocate"

  source_image_reference {
    offer     = var.linux.vm-image.offer
    publisher = var.linux.vm-image.publisher
    sku       = var.linux.vm-image.sku
    version   = var.linux.vm-image.version
  }

  os_disk {
   name = "${local.prefix}-OSDISK-DVWA-${count.index+1}-${random_string.random-lab-vm[count.index].result}"
   caching              = "ReadWrite"
   storage_account_type = "Standard_LRS"

  }

  admin_ssh_key {
    username   = var.admin-username
    public_key = "${tls_private_key.private-key[count.index].public_key_openssh}"
  }
  disable_password_authentication = true
  custom_data = base64encode(data.template_file.dvwa-vm-cloud-init[count.index].rendered)

  admin_username = var.admin-username
  admin_password = var.admin-password

  computer_name = "DVWA-${count.index+1}"

  tags = {
    terraform = "true"
    environment = var.environment
  }
}
