
data "template_file" "jump-vm-cloud-init" {
  count = var.num-of-labs
  template = templatefile("${path.module}/data/jump.ps1", {
    ADMIN-PASSWORD = var.admin-password,
    ADMIN-USER     = var.admin-username,
    PRIV-KEY       = tls_private_key.private-key.private_key_pem,
    KALI-PRIV-IP   = module.labvNic[count.index].kali-vnic.ip,
    CENTOS-PRIV-IP = module.labvNic[count.index].centos-vnic.ip,
    DVWA-PRIV-IP   = module.labvNic[count.index].dvwa-vnic.ip,
    JUMP-PRIV-IP   = module.labvNic[count.index].jump-vnic.priv-ip,
    JUMP-PUB-IP    = module.labvNic[count.index].jump-vnic.pub-ip
  })
}

# Create Windows Jump Server
resource "azurerm_windows_virtual_machine" "jump-vm" {
  count = var.num-of-labs

  name                  = "${local.prefix}-VM-JUMP-${count.index + 1}-${random_string.random-lab-vm[count.index].result}"
  location              = local.location
  resource_group_name   = var.resource-group-name
  size                  = var.jump.vm-size
  network_interface_ids = [module.labvNic[count.index].jump-vnic.id]

  priority        = var.spot-vm.priority
  max_bid_price   = var.spot-vm.max-bid-price
  eviction_policy = "Deallocate"

  computer_name  = "JUMP-${count.index + 1}"
  admin_username = var.admin-username
  admin_password = var.admin-password

  os_disk {
    name                 = "${local.prefix}-OSDISK-JUMP-${count.index + 1}-${random_string.random-lab-vm[count.index].result}"
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
    terraform   = "true"
    environment = var.environment
  }
}

# wait for jump ready
resource "time_sleep" "wait-for-jump-vm" {

  create_duration = "30s"

  depends_on = [azurerm_windows_virtual_machine.jump-vm]
}

locals {
  init-jump-command = [
    for ip in module.labvNic[*].dvwa-vnic.ip :
      "Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('http://${ip}/init-jump.ps1'))"
  ]

  stopfw-command   = "Set-NetFirewallProfile -All -Enabled False"
  enablerm-command = "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'))"
  exit-code-hack   = "exit 0"

  powershell_command = [
    for init in local.init-jump-command[*] :
      "${local.stopfw-command}; ${local.enablerm-command}; ${init}; ${local.exit-code-hack}" //
  ]
}

resource "azurerm_virtual_machine_extension" "init-jump" {

  depends_on = [
    time_sleep.wait-for-jump-vm,
    time_sleep.wait-for-dvwa-vm
  ]

  count = var.num-of-labs
  name  = "${local.prefix}-init-JUMP-${count.index + 1}-${random_string.random-lab-vm[count.index].result}"

  virtual_machine_id   = azurerm_windows_virtual_machine.jump-vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command[count.index]}\""
    }
SETTINGS
}


# resource "azurerm_virtual_machine_extension" "init-jump" {
#
#   count = var.num-of-labs
#   depends_on = [ time_sleep.wait-for-jump-vm ]
#   name                       = "${local.prefix}-init-JUMP-${count.index+1}-${random_string.random-lab-vm[count.index].result}"
#
#   virtual_machine_id       = azurerm_windows_virtual_machine.jump-vm[count.index].id
#   publisher                  = "Microsoft.CPlat.Core"
#   type                       = "RunCommandWindows"
#   type_handler_version       = "1.1"
#   auto_upgrade_minor_version = true
#   settings                   = <<SETTINGS
# {
#   "script" : ${jsonencode(compact(concat(split("\n",data.template_file.jump-vm-cloud-init[count.index].rendered))))}
# }
# SETTINGS
# }
