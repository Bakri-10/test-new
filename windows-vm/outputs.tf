output "admin_password" {
  sensitive = false
  #value     = [ for vm in azurerm_windows_virtual_machine.main : vm.admin_password ]
  value = local.admin_password
 }
output "data_disk_count" {
  sensitive = false
  #value     = [ for vm in azurerm_windows_virtual_machine.main : vm.admin_password ]
  value = var.data_disk_count
 }
output "input_validation" {
    value = [for inst in local.validation_map : inst.state]
 }