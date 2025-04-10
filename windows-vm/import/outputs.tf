// Outputs for the import process
output "import_details" {
  value = {
    vm_id = azurerm_windows_virtual_machine.import.id
    rg_id = azurerm_resource_group.import.id
    nic1_id = azurerm_network_interface.import_nic1.id
    nic2_id = var.subnet2_id != "" ? azurerm_network_interface.import_nic2[0].id : null
    location = azurerm_resource_group.import.location
    vm_size = azurerm_windows_virtual_machine.import.size
    extension_count = var.include_extensions ? length(jsondecode(var.extensions_json).extensions) : 0
    extension_names = var.include_extensions ? keys(jsondecode(var.extensions_json).extensions) : []
  }
} 