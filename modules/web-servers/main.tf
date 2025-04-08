resource "azurerm_resource_group" "WEB-ResourceGroup" {
  name     = var.web_resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "web_lb_pip" {
  name                = "WEB-LB-PIP"
  location            = azurerm_resource_group.WEB-ResourceGroup.location
  resource_group_name = azurerm_resource_group.WEB-ResourceGroup.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_lb" "web-lb" {
  name                = "WEB-LB"
  location            = azurerm_resource_group.WEB-ResourceGroup.location
  resource_group_name = azurerm_resource_group.WEB-ResourceGroup.name
  sku                 = "Basic"

  frontend_ip_configuration {
    name                 = "WEBPublicIPAddress"
    public_ip_address_id = azurerm_public_ip.web_lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "web_lb_backend" {
  loadbalancer_id = azurerm_lb.web-lb.id
  name            = "BackendPool"
}

resource "azurerm_lb_probe" "web_lb_probe" {
  loadbalancer_id     = azurerm_lb.web-lb.id
  name                = "HTTP-Probe"
  port                = 80
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "web_http_rule" {
  loadbalancer_id                = azurerm_lb.web-lb.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "WEBPublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_lb_backend.id]
  probe_id                       = azurerm_lb_probe.web_lb_probe.id
}

resource "azurerm_linux_virtual_machine_scale_set" "web_vmss" {
  name                = "WEB-VMSS"
  location            = azurerm_resource_group.WEB-ResourceGroup.location
  resource_group_name = azurerm_resource_group.WEB-ResourceGroup.name
  sku                 = "Standard_D2s_v3" # 2 vCPU, 4GB RAM
  instances           = 1                 
  admin_username      = "adminuser"
  admin_password      = "AZpassword098"

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/Sushma/.ssh/id_rsa_azure.pub") 
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-lts"
    version   = "latest"
  }


  os_disk {
    storage_account_type = "Standard_LRS" # HDD
    caching              = "ReadWrite"
  }

  custom_data = base64encode(<<-EOT
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y apache2
    sudo systemctl enable apache2
    sudo systemctl start apache2
    sudo systemctl status apache2
  EOT
  )

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      subnet_id                              = var.web_subnet_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web_lb_backend.id]
      primary                                = true
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "web_vmss_autoscale" {
  name                = "Web-VMSS-Autoscale"
  resource_group_name = azurerm_resource_group.WEB-ResourceGroup.name
  location            = azurerm_resource_group.WEB-ResourceGroup.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.web_vmss.id
  enabled             = true

  profile {
    name = "default"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}


# NSG Bastion web_vmss
resource "azurerm_network_security_group" "web_vmss_subnet_nsg" {
  name                = "web-vmss-subnet-nsg"
  location            = azurerm_resource_group.WEB-ResourceGroup.location
  resource_group_name = azurerm_resource_group.WEB-ResourceGroup.name

  /*
  security_rule {
    name                       = "allow-bastion-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.5.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }
*/

  # HTTP
  security_rule {
    name                       = "allow-http-internet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }
}


# NSG WEB-VMSS
resource "azurerm_subnet_network_security_group_association" "web_vmss_subnet_nsg_association" {
  subnet_id                 = var.web_subnet_id
  network_security_group_id = azurerm_network_security_group.web_vmss_subnet_nsg.id
}

