output "jump-vnic" {
  value = {
    id = azurerm_network_interface.jump-vm-nic.id
    priv-ip = azurerm_network_interface.jump-vm-nic.private_ip_address
    pub-ip = azurerm_public_ip.jump-public-ip.ip_address
  }
}

output "centos-vnic" {
  value = {
    id = azurerm_network_interface.centos-vm-nic.id
    ip = azurerm_network_interface.centos-vm-nic.private_ip_address
  }
}

output "dvwa-vnic" {
  value = {
    id = azurerm_network_interface.dvwa-vm-nic.id
    ip = azurerm_network_interface.dvwa-vm-nic.private_ip_address
  }
}

output "kali-vnic" {
  value = {
    id = azurerm_network_interface.kali-vm-nic.id
    ip = azurerm_network_interface.kali-vm-nic.private_ip_address
  }
}
