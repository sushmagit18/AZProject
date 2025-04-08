variable "fw_resource_group_name" {
  type    = string
  default = "FW-ResourceGroup"
}

variable "location" {
  type    = string
  default = "canadacentral"
}

variable "dmz_subnet_id" {
  description = "Subnet ID vnet module"
  type        = string
}