output "jump_public_ip_address" {
  value = module.labvNic[*].jump-vnic.pub-ip
}
