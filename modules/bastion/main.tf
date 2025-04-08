resource "azurerm_resource_group" "BASTION-ResourceGroup" {
  name     = var.bastion_resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  location            = azurerm_resource_group.BASTION-ResourceGroup.location
  resource_group_name = azurerm_resource_group.BASTION-ResourceGroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = "bastion-host"
  location            = azurerm_resource_group.BASTION-ResourceGroup.location
  resource_group_name = azurerm_resource_group.BASTION-ResourceGroup.name

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

