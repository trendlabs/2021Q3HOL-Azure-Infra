
data "template_file" "jump-vm-cloud-init" {
  count = var.num-of-labs
  template = templatefile("${path.module}/data/jump.ps1", {
      ADMIN-PASSWORD = var.admin-password,
      ADMIN-USER = var.admin-username,
      PRIV-KEY = tls_private_key.private-key[count.index].private_key_pem,
      KALI-PRIV-IP = module.labvNic[count.index].kali-vnic.ip,
      CENTOS-PRIV-IP = module.labvNic[count.index].centos-vnic.ip,
      DVWA-PRIV-IP = module.labvNic[count.index].dvwa-vnic.ip,
      JUMP-PRIV-IP = module.labvNic[count.index].jump-vnic.priv-ip
  })
}

# Create Windows Jump Server
resource "azurerm_windows_virtual_machine" "jump-vm" {
  count = var.num-of-labs

  name = "${local.prefix}-VM-JUMP-${count.index+1}-${random_string.random-lab-vm[count.index].result}"
  location              = local.location
  resource_group_name   = var.resource-group-name
  size                  = var.jump.vm-size
  network_interface_ids = [module.labvNic[count.index].jump-vnic.id]

  priority = var.spot-vm.priority
  max_bid_price = var.spot-vm.max-bid-price
  eviction_policy = "Deallocate"

  computer_name = "JUMP-${count.index+1}"
  admin_username = var.admin-username
  admin_password = var.admin-password

  os_disk {
    name = "${local.prefix}-OSDISK-JUMP-${count.index+1}-${random_string.random-lab-vm[count.index].result}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    offer     = var.jump.vm-image.offer
    publisher = var.jump.vm-image.publisher
    sku       = var.jump.vm-image.sku
    version   = var.jump.vm-image.version
  }

  enable_automatic_updates = true
  provision_vm_agent       = true

  tags = {

    environment = var.environment
  }
}

resource "azurerm_virtual_machine_extension" "init-jump" {

  count = var.num-of-labs

  name                       = "${local.prefix}-init-JUMP-${count.index+1}-${random_string.random-lab-vm[count.index].result}"

  virtual_machine_id       = azurerm_windows_virtual_machine.jump-vm[count.index].id
  publisher                  = "Microsoft.CPlat.Core"
  type                       = "RunCommandWindows"
  type_handler_version       = "1.1"
  auto_upgrade_minor_version = true
  settings                   = <<SETTINGS
{
  "script" = ${jsonencode(compact(concat(split("\n",data.template_file.jump-vm-cloud-init[count.index].rendered))))}
}
SETTINGS
}
