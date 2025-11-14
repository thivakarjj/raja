vmss_configs = {
  "app-vmss" = {
    vmss_name       = "app-vmss"
    rg_name         = "devops-giri"
    location        = "eastus"
    vm_size         = "Standard_DS2_v2"
    admin_username  = "azureuser"
    custom_image_id = "/subscriptions/ff61c832-819b-46dc-b485-7196a37165bc/resourceGroups/devops-giri/providers/Microsoft.Compute/galleries/linux/images/linux/versions/0.0.1"
    subnet_id       = "/subscriptions/ff61c832-819b-46dc-b485-7196a37165bc/resourceGroups/devops-giri/providers/Microsoft.Network/virtualNetworks/devops-vnet/subnets/devcenterpoc"
    ip_configurations = {
      ip0 = { name = "ipconfig0" }
    }
    zones                        = [1, 2, 3]
    os_disk_caching              = "ReadWrite"
    os_disk_storage_account_type = "Premium_LRS"
    os_disk_size_gb              = 30
    key_vault_id                 = "/subscriptions/ff61c832-819b-46dc-b485-7196a37165bc/resourceGroups/devops-giri/providers/Microsoft.KeyVault/vaults/devcenter-vault-demo"
    tenant_id                    = "6b464218-6814-4c2e-a102-a5a7fc8452a9"
    instance_count               = 2
    min_instance_count           = 1
    max_instance_count           = 5
    environment                  = "dev"
    enable_automatic_upgrade     = true
  }
}
