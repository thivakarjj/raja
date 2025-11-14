resource "random_password" "vm_admin_password" {
  length      = 20
  min_lower   = 2
  min_upper   = 4
  min_numeric = 5
  special     = true
}

resource "azurerm_key_vault_secret" "vm_password" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = "${var.vmss_name}-password"
  value        = random_password.vm_admin_password.result
  key_vault_id = var.key_vault_id
  depends_on   = [random_password.vm_admin_password]
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  location            = var.location
  resource_group_name = var.rg_name
  admin_username      = var.admin_username
  admin_password = var.key_vault_id != "" ? azurerm_key_vault_secret.vm_password[0].value : random_password.vm_admin_password.result
  source_image_id = var.custom_image_id
  disable_password_authentication = false

  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != "" ? [var.ssh_public_key] : []
    content {
      username   = var.admin_username
      public_key = admin_ssh_key.value
    }
  }
  sku       = var.vm_size
  instances = var.initial_instance_count

  zone_balance = true
  zones        = var.zones
  upgrade_mode        = var.enable_automatic_upgrade ? "Automatic" : "Manual"

  os_disk {
    caching                = var.os_disk_caching
    storage_account_type   = var.os_disk_storage_account_type
    disk_size_gb           = var.os_disk_size_gb
    disk_encryption_set_id = null
  }

  identity {
    type = "SystemAssigned"
  }

network_interface {
  name    = "${var.vmss_name}-nic"
  primary = true

  dynamic "ip_configuration" {
    for_each = var.ip_configurations

    content {
      name      = ip_configuration.value.name
      primary   = true
      subnet_id = var.subnet_id
    }
  }
}


  tags = {
    environment = var.environment
  }
}

resource "azurerm_key_vault_access_policy" "vmss_policy" {
  count        = var.key_vault_id != "" ? 1 : 0
  key_vault_id = var.key_vault_id
  tenant_id    = var.tenant_id
  object_id    = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id

  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "${var.vmss_name}-autoscale"
  location            = var.location
  resource_group_name = var.rg_name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id
  enabled             = true

  profile {
    name = "default"

    capacity {
      minimum = tostring(var.min_instance_count)
      maximum = tostring(var.max_instance_count)
      default = tostring(var.initial_instance_count)
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        operator           = "GreaterThan"
        threshold          = 80
        time_grain         = "PT1M"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        statistic          = "Average"
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
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        operator           = "LessThan"
        threshold          = 40
        time_grain         = "PT1M"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        statistic          = "Average"
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
