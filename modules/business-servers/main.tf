resource "azurerm_resource_group" "BUSINESS-ResourceGroup" {
  name     = var.business_resource_group_name
  location = var.location
}

resource "azurerm_lb" "business-lb" {
  name                = "BUSINESS-LB"
  location            = azurerm_resource_group.BUSINESS-ResourceGroup.location
  resource_group_name = azurerm_resource_group.BUSINESS-ResourceGroup.name
  sku                 = "Basic"

  frontend_ip_configuration {
    name                          = "BUSINESSStaticIPAddress"
    private_ip_address            = "10.0.3.100"
    private_ip_address_allocation = "Static"
    subnet_id                     = var.business_subnet_id
  }
}

resource "azurerm_lb_backend_address_pool" "business_lb_backend" {
  loadbalancer_id = azurerm_lb.business-lb.id
  name            = "BackendPool"
}

resource "azurerm_lb_probe" "business_lb_probe" {
  loadbalancer_id     = azurerm_lb.business-lb.id
  name                = "Business-Probe"
  port                = 80
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "business_http_rule" {
  loadbalancer_id                = azurerm_lb.business-lb.id
  name                           = "business-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "BUSINESSStaticIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.business_lb_backend.id]
  probe_id                       = azurerm_lb_probe.business_lb_probe.id
}

resource "azurerm_windows_virtual_machine_scale_set" "bus_vmss" {
  name                = "BUS-VMSS"
  location            = azurerm_resource_group.BUSINESS-ResourceGroup.location
  resource_group_name = azurerm_resource_group.BUSINESS-ResourceGroup.name
  sku                 = "Standard_D2s_v3" # 2 vCPU, 4GB RAM
  instances           = 1                 
  admin_username      = "adminuser"
  admin_password      = "Azpassword098"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS" # HDD
    caching              = "ReadWrite"
  }


  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      subnet_id                              = var.business_subnet_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.business_lb_backend.id]
      primary                                = true
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "business_vmss_autoscale" {
  name                = "Business-VMSS-Autoscale"
  resource_group_name = azurerm_resource_group.BUSINESS-ResourceGroup.name
  location            = azurerm_resource_group.BUSINESS-ResourceGroup.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.bus_vmss.id
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
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.bus_vmss.id
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
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.bus_vmss.id
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



# NSGbusiness_vmss
resource "azurerm_network_security_group" "business_vmss_subnet_nsg" {
  name                = "business-vmss-subnet-nsg"
  resource_group_name = azurerm_resource_group.BUSINESS-ResourceGroup.name
  location            = azurerm_resource_group.BUSINESS-ResourceGroup.location

  # HTTP
  security_rule {
    name                       = "allow-web-http-https"
    priority                   = 200 
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.3.0/24"
  }
}



# NSG Business-VMSS
resource "azurerm_subnet_network_security_group_association" "business_vmss_subnet_nsg_association" {
  subnet_id                 = var.business_subnet_id
  network_security_group_id = azurerm_network_security_group.business_vmss_subnet_nsg.id
}