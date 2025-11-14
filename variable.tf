variable "vmss_configs" {
  description = "Map of VMSS configurations. Use keys for each vmss instance."
  type = map(object({
    vmss_name                    = string
    rg_name                      = string
    location                     = string
    vm_size                      = string
    admin_username               = string
    custom_image_id              = string
    subnet_id                    = string
    ip_configurations            = map(object({name = string}))
    zones                        = list(string)
    os_disk_caching              = string
    os_disk_storage_account_type = string
    os_disk_size_gb              = number
    key_vault_id                 = string
    tenant_id                    = string
    instance_count               = number
    min_instance_count           = number
    max_instance_count           = number
    environment                  = string
    enable_automatic_upgrade     = bool
  }))
  default = {}
}
