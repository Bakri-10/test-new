output "vm_id" {
  sensitive = false
  value = data.azurerm_virtual_machine.maintaining.id
 }