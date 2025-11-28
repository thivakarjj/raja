vmss_configs = {
  "app-vmss" = {
    vmss_name       = "devops-vmss"
    rg_name         = "devops-giri"
    location        = "eastus2"
    vm_size         = "Standard_NV4as_v4"
    admin_username  = "azureuser"
    use_marketplace = true
    publisher       = "RedHat"
    offer           = "RHEL"
    sku             = "8-lvm-gen2"
    version         = "latest"
    #custom_image_id = "/subscriptions/ff61c832-819b-46dc-b485-7196a37165bc/resourceGroups/devops-giri/providers/Microsoft.Compute/galleries/linux/images/linux/versions/0.0.1"
    subnet_id       = "/subscriptions/21a91bed-d635-447a-aec9-e80f32c23443/resourceGroups/devops-giri/providers/Microsoft.Network/virtualNetworks/vnet-eastus2/subnets/dev"
    nic_name        = "nic-app"
    ip_configurations = {
      ip0 = { name = "ipconfig0" }
    }
    zones                        = null
    os_disk_caching              = "ReadWrite"
    os_disk_storage_account_type = "Premium_LRS"
    os_disk_size_gb              = 120
    key_vault_id                 = "/subscriptions/21a91bed-d635-447a-aec9-e80f32c23443/resourceGroups/devops-giri/providers/Microsoft.KeyVault/vaults/azuredevopsvault09"
    key_vault_name               = "azuredevopsvault09"
    tenant_id                    = "8a18c8e4-c77a-4b73-8926-b2430f6c6a9a"
    instance_count               = 1
    min_instance_count           = 1
    max_instance_count           = 5
    environment                  = "dev"
    #agent_pat_secret_name        = "pat"
    agent_user                   = "adodevagent"
    agent_version                = "4.264.2"
    terraform_version            = "1.11.4"
  }
}

subscription_id = "21a91bed-d635-447a-aec9-e80f32c23443"
client_id       = "dd6b0392-1f13-4469-8c8b-a739751ad609"
client_secret   = "Imm8Q~-N~oDlg49iiDFzxdF1kkleh4hqXArAicIi"
tenant_id       = "8a18c8e4-c77a-4b73-8926-b2430f6c6a9a"

azuredevops_org_service_url    = "https://dev.azure.com/achuthadevops25"
azuredevops_pat_key_vault_id   = "/subscriptions/21a91bed-d635-447a-aec9-e80f32c23443/resourceGroups/devops-giri/providers/Microsoft.KeyVault/vaults/azuredevopsvault09"
azdo_org_url          = "https://dev.azure.com/achuthadevops25"
agent_pat_secret_name = "pat"
agent_pool_name = "Dev-vmss-pool"