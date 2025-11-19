variable "vmss_configs" {
  description = "Map of VMSS configurations. Use keys for each vmss instance."
  type = map(object({
    vmss_name                    = string
    rg_name                      = string
    location                     = string
    vm_size                      = string
    admin_username               = string
    #custom_image_id              = string
    subnet_id                    = string
    nic_name                     = string
    ip_configurations            = map(object({ name = string }))
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
    agent_pat_secret_name        = string
    key_vault_name               = string
    agent_version                = string
    agent_user                   = string
  }))

  default = {}
}

variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

variable "image_version" {
  type    = string
  default = "latest"
}

variable "azdo_org_url" {
  type = string
}

variable "agent_pool_name" {
  type = string
}

variable "agent_pat_secret_name" {
  type = string
}

variable "azuredevops_org_service_url" {
  description = "Azure DevOps organization service URL"
  type        = string
}

variable "azuredevops_pat_key_vault_id" {
  description = "Key Vault ID that contains the Azure DevOps PAT secret"
  type        = string
}

variable "azuredevops_pat_secret_name" {
  description = "Secret name in Key Vault for the Azure DevOps PAT"
  type        = string
}