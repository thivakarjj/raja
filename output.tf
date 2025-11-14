# Expose module outputs for all instances
output "vmss_ids" {
  description = "Map of VMSS ids keyed by vmss_configs key"
  value       = { for k, m in module.linux_vmss : k => m.vmss_id }
}

output "vmss_names" {
  description = "Map of VMSS names keyed by vmss_configs key"
  value       = { for k, m in module.linux_vmss : k => m.vmss_name }
}

output "autoscale_ids" {
  description = "Map of autoscale setting ids keyed by vmss_configs key"
  value       = { for k, m in module.linux_vmss : k => m.autoscale_setting_id }
}
