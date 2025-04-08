variable "business_resource_group_name" {
  type    = string
  default = "BUSINESS-ResourceGroup"
}

variable "location" {
  type    = string
  default = "canadacentral"
}

variable "business_subnet_id" {
  description = "Subnet ID vnet module"
  type        = string
}


