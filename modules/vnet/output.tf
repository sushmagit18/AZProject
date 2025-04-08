output "vnet_id" {
  value = azurerm_virtual_network.VNET.id
}

output "dmz_subnet_id" {
  value = azurerm_subnet.DMZSubnet.id
}

output "web_subnet_id" {
  value = azurerm_subnet.WEBSubnet.id
}

output "business_subnet_id" {
  value = azurerm_subnet.BusinessSubnet.id
}

output "data_subnet_id" {
  value = azurerm_subnet.DataSubnet.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.AzureBastionSubnet.id
}