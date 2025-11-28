variable "vmss_name" {
  type = string
}

variable "agent_pool_name" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_DS2_v2"
}

variable "admin_username" {
  type = string
}

#variable "custom_image_id" {
  #type    = string
  #default = ""
#}

variable "use_marketplace" {
  type    = bool
  default = false
}

variable "publisher" {
  type    = string
  default = ""
}

variable "offer" {
  type    = string
  default = ""
}

variable "sku" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type = string
}

variable "nic_name" {
  type = string
}

variable "ip_config_name" {
  type = string
}

variable "zones" {
  type    = list(number)
  default = []
}

variable "os_disk_caching" {
  type    = string
  default = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  type    = string
  default = "Premium_LRS"
}

variable "os_disk_size_gb" {
  type    = number
  default = 30
}

variable "key_vault_id" {
  type    = string
  default = ""
}

variable "tenant_id" {
  type = string
}

variable "initial_instance_count" {
  type    = number
  default = 2
}

variable "min_instance_count" {
  type    = number
  default = 1
}

variable "max_instance_count" {
  type    = number
  default = 5
}

variable "environment" {
  type    = string
  default = ""
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Optional SSH public key. Leave empty to rely on password authentication."
}

variable "image_version" {
  type    = string
  default = "latest"
}

variable "agent_version" {
  description = "Azure DevOps agent version to install"
  type        = string
}

variable "agent_user" {
  description = "OS user under which the ADO agent runs"
  type        = string
}

variable "key_vault_name" {
  description = "Name of Key Vault that stores the ADO PAT"
  type        = string
}
variable "azdo_org_url" {
  description = "Azure DevOps organization URL passed to the VM agent script"
  type        = string
}

variable "agent_pat_secret_name" {
  description = "Name of the Key Vault secret that stores the Azure DevOps PAT"
  type        = string
}

variable "terraform_version" {
  type        = string
  description = "Terraform CLI version to install on VMSS agents"
}



