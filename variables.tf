######## Azure account information ##############
variable "azure_subscription_id" {
  type        = string
  description = "Azure Subcription ID"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "azure_client_id" {
  type        = string
  description = "Azure Client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure Client Secret"
}

########### Lab specific section ###############

variable "environment" {
  type = string
}

variable "create-rgs" {
  type = bool
}

variable "admin-username" {
  type        = string
  description = "Admin Username for Lab"
}

variable "admin-password" {
  type        = string
  description = "Admin Password for Lab"
}

variable "network-vnet-cidr" {
  type        = string
  description = "VNET cidr block"
}

variable "jump-subnet-cidr" {
  type        = string
  description = "Jump VM subnet cidr block"
}

variable "linux-subnet-cidr" {
  type        = string
  description = "Linux VM subnet cidr block"
}

variable "rg_list" {
  type        = map(any)
  description = "Resource Group list"
  default = {
    "VN" = 4 // resource group "VN" has 4 labs
  }
}

# variable "specialist-ips" {
#   type        = map
#   description = "Specialist IP list"
# }
