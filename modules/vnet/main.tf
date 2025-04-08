resource "azurerm_resource_group" "VNET-ResourceGroup" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "VNET" {
  name                = "VNET"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_resource_group.VNET-ResourceGroup]
}

resource "azurerm_subnet" "DMZSubnet" {
  name                 = "DMZSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "WEBSubnet" {
  name                 = "WEBSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "BusinessSubnet" {
  name                 = "BusinessSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "DataSubnet" {
  name                 = "DataSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["10.0.5.0/24"]
}


