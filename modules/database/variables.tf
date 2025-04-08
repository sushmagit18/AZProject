variable "db_resource_group_name" {
  type    = string
  default = "DB-ResourceGroup"
}

variable "location" {
  type    = string
  default = "canadacentral"
}

variable "data_subnet_id" {
  description = "Subnet ID vnet module"
  type        = string
}

