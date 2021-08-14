output "jump_ip_address" {
  value = module.lab-VM-provision[*].jump_public_ip_address
}
