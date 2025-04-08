variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "VNET-ResourceGroup"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "canadacentral"
}