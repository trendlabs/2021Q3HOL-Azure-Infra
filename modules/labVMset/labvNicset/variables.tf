########### General variables ##########

variable "environment" {
  type = string
  description = "HOL envrionment name"
}

variable "resource-group-name" {
  type = string
  description = "Resource Group name"
}

variable "prefix" {
  type = string
}

variable "suffix" {
  type = string
}

variable "location" {
  type = string
  description = "Resource Group location"
}

variable jump-subnet-id {
  type = string
  description = "Jump Subnet ID"
}

variable linux-subnet-id {
  type = string
  description = "Linux Subnet ID"
}
