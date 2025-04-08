variable "web_resource_group_name" {
  type    = string
  default = "WEB-ResourceGroup"
}

variable "location" {
  type    = string
  default = "canadacentral"
}


variable "web_subnet_id" {
  description = "Subnet ID vnet module"
  type        = string
}

