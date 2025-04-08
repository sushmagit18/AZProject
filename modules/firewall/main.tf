resource "azurerm_resource_group" "FW-ResourceGroup" {
  name     = var.fw_resource_group_name
  location = var.location
}

resource "azurerm_lb" "nva-lb" {
  name                = "nvalb"
  location            = azurerm_resource_group.FW-ResourceGroup.location
  resource_group_name = azurerm_resource_group.FW-ResourceGroup.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name      = "nvalb-frontend"
    subnet_id = var.dmz_subnet_id
  }
}

resource "azurerm_lb_backend_address_pool" "nva_lb_backend" {
  loadbalancer_id = azurerm_lb.nva-lb.id
  name            = "nva-backend-pool"
}

resource "azurerm_lb_probe" "nva_lb_probe" {
  loadbalancer_id     = azurerm_lb.nva-lb.id
  name                = "Nva-Probe"
  port                = 80
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "nva_http_rule" {
  loadbalancer_id                = azurerm_lb.nva-lb.id
  name                           = "nva-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "NvaStaticIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.nva_lb_backend.id]
  probe_id                       = azurerm_lb_probe.nva_lb_probe.id
}

# NVA
resource "azurerm_network_interface" "nva_nic" {
  count                = 2
  name                 = "nva-nic-${count.index}"
  location            = azurerm_resource_group.FW-ResourceGroup.location
  resource_group_name = azurerm_resource_group.FW-ResourceGroup.name

  ip_configuration {
    name                          = "internal-${count.index}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.dmz_subnet_id
  }
}

# NIC GWLB
resource "azurerm_network_interface_backend_address_pool_association" "nva_assoc" {
  count                   = 2
  ip_configuration_name   = "internal-${count.index}" 
  network_interface_id    = azurerm_network_interface.nva_nic[count.index].id
  backend_address_pool_id = azurerm_lb_backend_address_pool.nva_lb_backend.id
}


# NVA,（Ubuntu VM)
resource "azurerm_linux_virtual_machine" "nva_vm" {
  count                = 2
  name                 = "nva-vm-${count.index}"
  location            = azurerm_resource_group.FW-ResourceGroup.location
  resource_group_name = azurerm_resource_group.FW-ResourceGroup.name
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nva_nic[count.index].id
  ]

  admin_ssh_key {
    username   = "yan"
    public_key = file("C:/Users/Sushma/.ssh/id_rsa_azure.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = "byol"
    version   = "latest"
  }

}


resource "azurerm_network_security_group" "nva_nsg" {
  name                = "nva-nsg"
  location            = azurerm_resource_group.FW-ResourceGroup.location
  resource_group_name = azurerm_resource_group.FW-ResourceGroup.name

  security_rule {
    name                       = "allow-gwlb-traffic"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#  NSG NIC
resource "azurerm_network_interface_security_group_association" "nva_nic_nsg" {
  count                    = 2
  network_interface_id     = azurerm_network_interface.nva_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nva_nsg.id
}