########### General variables ##########
variable "num-of-labs" {
  type        = number
  description = "Number of labs to be provisioned"
}

variable "environment" {
  type        = string
  description = "HOL envrionment name"
}

variable "resource-group-name" {
  type        = string
  description = "Resource Group name"
}

variable "virtual-network-name" {
  type        = string
  description = "Virtual Network name"
}

variable "admin-username" {
  type        = string
  description = "Lab Admin Username"
}

variable "admin-password" {
  type        = string
  description = "Lab Admin Password"
}

variable "install-dvwa" {
  type = bool
}

variable "install-dnscat" {
  type = bool
}

####### Network variables ###############
variable "spot-vm" {
  type = map(string)
}

variable "jump" {
  type = object({
    subnet-id   = string
    subnet-name = string
    vm-size     = string
    vm-image    = map(string)
  })
}

variable "linux" {
  type = object({
    subnet-id   = string
    subnet-name = string
    vm-size     = string
    vm-image    = map(string)
  })
}
