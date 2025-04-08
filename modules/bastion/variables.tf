variable "bastion_resource_group_name" {
  type    = string
  default = "BASTION-ResourceGroup"
}

variable "location" {
  type    = string
  default = "canadacentral"
}

variable "bastion_subnet_id" {
  description = "Subnet ID vnet module"
  type        = string
}
