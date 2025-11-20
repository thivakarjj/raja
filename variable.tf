variable "vmss_configs" {
  description = "Map of VMSS configurations. Use keys for each vmss instance."
  type = map(object({
    vmss_name                    = string
    rg_name                      = string
    location                     = string
    vm_size                      = string
    admin_username               = string
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
    key_vault_name               = string
    agent_version                = string
    agent_user                   = string
  }))

  default = {}
}

variable "subscription_id" {
  description = "Azure subscription ID"
}

variable "client_id" {
  description = "Service principal client ID"
}

variable "client_secret" {
  description = "Service principal client secret"
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
}

variable "azdo_org_url" {
  description = "Azure DevOps org URL"
  type        = string
}

variable "agent_pool_name" {
  description = "ADO agent pool name"
  type        = string
}

variable "agent_pat_secret_name" {
  description = "PAT secret name for VMSS agent"
  type        = string
}

variable "azuredevops_org_service_url" {
  description = "ADO org service URL"
  type        = string
}

variable "azuredevops_pat_key_vault_id" {
  description = "Key Vault ID for provider PAT"
  type        = string
}

