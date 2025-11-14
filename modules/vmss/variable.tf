variable "vmss_name" {
  type        = string
  description = "Name of the Virtual Machine Scale Set (VMSS). This value is used for resource naming and tagging."
}

variable "rg_name" {
  type        = string
  description = "Name of the resource group where the VMSS and associated resources will be deployed."
}

variable "location" {
  type        = string
  description = "Azure region in which the VMSS resources will be created."
}

variable "vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
  description = "The size/SKU of the virtual machines in the scale set. Example: Standard_DS2_v2."
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM instances in the scale set."
}

variable "custom_image_id" {
  type        = string
  description = "Resource ID of the custom image used to deploy VMSS instances. Required for custom image-based VMSS."
}

variable "sku" {
  type        = string
  default     = ""
  description = "Optional SKU used for supporting custom image versions or marketplace images (if applicable). Leave empty for custom images."
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the subnet into which VMSS network interfaces will be deployed."
}

variable "zones" {
  type        = list(number)
  default     = []
  description = "List of availability zones where VMSS instances will be deployed. Leave empty for non-zonal deployments."
}

variable "os_disk_caching" {
  type        = string
  description = "Caching mode for the OS disk. Accepted values include ReadWrite and ReadOnly."
}

variable "os_disk_storage_account_type" {
  type        = string
  description = "Storage account type for the OS disk. Example values: Premium_LRS, StandardSSD_LRS, Standard_LRS."
}

variable "os_disk_size_gb" {
  type        = number
  description = "Size of the OS disk in GB for each VMSS instance."
}

variable "key_vault_id" {
  type        = string
  description = "Resource ID of the Azure Key Vault used for storing the VM admin password. Leave empty to skip Key Vault integration."
}

variable "tenant_id" {
  type        = string
  description = "Azure Active Directory tenant ID required for granting access to VMSS managed identity in Key Vault."
}

variable "initial_instance_count" {
  type        = number
  description = "Number of VM instances to create in the scale set during initial deployment."
}

variable "min_instance_count" {
  type        = number
  description = "Minimum number of VM instances allowed in autoscale operations."
}

variable "max_instance_count" {
  type        = number
  description = "Maximum number of VM instances allowed in autoscale operations."
}

variable "environment" {
  type        = string
  description = "Environment tag value applied to VMSS resources. Examples: dev, test, prod."
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Optional SSH public key for enabling SSH authentication. Leave empty if password authentication is used."
}

variable "enable_automatic_upgrade" {
  type        = bool
  default     = true
  description = "Specifies whether VMSS should use automatic OS upgrades. When enabled, Azure automatically applies OS image updates."
}

variable "ip_configurations" {
  description = "Map defining the IP configurations to apply to each VMSS network interface. Each map entry represents an ip_configuration block with a unique name."
  type = map(object({
    name = string
  }))
}
