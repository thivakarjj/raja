terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.0.0"
    }
  }
}

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

resource "azuredevops_agent_pool" "vmss_pool" {
  name = var.agent_pool_name
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  location            = var.location
  resource_group_name = var.rg_name
  admin_username      = var.admin_username

  admin_password                  = var.key_vault_id != "" ? azurerm_key_vault_secret.vm_password[0].value : random_password.vm_admin_password.result
  disable_password_authentication = false

  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != "" ? [var.ssh_public_key] : []
    content {
      username   = var.admin_username
      public_key = admin_ssh_key.value
    }
  }

  source_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.image_version
  }

  sku       = var.vm_size
  instances = var.initial_instance_count

  zones        = var.zones
  upgrade_mode = "Manual"

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
    name    = var.nic_name
    primary = true

    ip_configuration {
      name      = var.ip_config_name
      primary   = true
      subnet_id = var.subnet_id

      public_ip_address {
        name                    = "${var.vmss_name}-pip-config"
        idle_timeout_in_minutes = 4
      }
    }
  }

  tags = {
    environment = var.environment
  }

  custom_data = base64encode(
    templatefile("${path.module}/scripts/ado-agent-install.sh.tpl", {
      azdo_org_url          = var.azdo_org_url
      agent_pool            = var.agent_pool_name
      key_vault_name        = var.key_vault_name
      agent_pat_secret_name = var.agent_pat_secret_name
      agent_version         = var.agent_version
      agent_user            = var.agent_user
    })
  )
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

resource "azurerm_role_assignment" "vmss_kv_secrets_user" {
  count                = var.key_vault_id != "" ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id
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
