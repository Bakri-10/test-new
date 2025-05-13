terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.101.0"
      configuration_aliases = [ 
          azurerm.adt
       ]
     }
  }
  required_version = ">=1.1.0"
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
 }
provider "azurerm" {
  alias                       = "adt"
  features {
    virtual_machine {
      delete_os_disk_on_deletion      = true
      graceful_shutdown               = false
    }
  }
 }

# Locals for naming and importing
locals {
  naming = {
    subscription_id           = data.azurerm_subscription.current.id
    location                  = var.location
  }
   
  # Import parameters
  vm_name                     = var.vm_name
  rg_name                     = var.resource_group_name
  vm_id                       = "${local.naming.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.Compute/virtualMachines/${local.vm_name}"
  
  # Collect NIC information
  nic_count                   = tonumber(var.nic_count)
  
  # Handle multiple NICs with comma separation
  # Split the NIC names by comma if provided, else use default naming
  nic_names_raw               = var.nic_names != "" ? split(",", var.nic_names) : []
  nic_names_trimmed           = [for name in local.nic_names_raw : trimspace(name)]
  nic_names                   = length(local.nic_names_trimmed) > 0 ? local.nic_names_trimmed : [
    for i in range(1, local.nic_count + 1) : "${local.vm_name}-nic-${format("%02d", i)}"
  ]
  
  # Clean NIC names and create IDs
  clean_nic_names             = [for name in local.nic_names : name if name != ""]
  nic_ids                     = {for name in local.clean_nic_names : 
    name => "${local.naming.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.Network/networkInterfaces/${name}"
  }
  
  # Collect disk information
  os_disk_name                = var.os_disk_name != null && var.os_disk_name != "" ? var.os_disk_name : "${local.vm_name}-disk-os"
  os_disk_id                  = "${local.naming.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.Compute/disks/${local.os_disk_name}"
  
  data_disk_count             = tonumber(var.data_disk_count)
  
  # Skip data disks processing if count is 0
  data_disk_names_raw         = var.data_disk_names != "" ? split(",", var.data_disk_names) : []
  data_disk_names_trimmed     = [for name in local.data_disk_names_raw : trimspace(name)]
  data_disk_names             = local.data_disk_count > 0 ? (
    length(local.data_disk_names_trimmed) > 0 ? local.data_disk_names_trimmed : [
      for i in range(0, local.data_disk_count) : "${local.vm_name}-data_disk-${i}"
    ]
  ) : []
  
  # Create data disk IDs as a map only if there are data disks
  data_disk_ids               = {for name in local.data_disk_names : 
    name => "${local.naming.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.Compute/disks/${name}"
  }
}

# Data sources
data "azurerm_subscription" "current" {}

# Get the resource group first
data "azurerm_resource_group" "target_rg" {
  provider = azurerm.adt
  name     = local.rg_name
}

# Get VM details
data "azurerm_virtual_machine" "existing" {
  provider            = azurerm.adt
  name                = local.vm_name
  resource_group_name = local.rg_name
}

# Get OS disk details
data "azurerm_managed_disk" "os_disk" {
  provider            = azurerm.adt
  name                = local.os_disk_name
  resource_group_name = local.rg_name
}

# Get data disk details
data "azurerm_managed_disk" "data_disks" {
  provider            = azurerm.adt
  for_each            = local.data_disk_count > 0 ? toset(local.data_disk_names) : toset([])
  name                = each.value
  resource_group_name = local.rg_name
}

# Get NIC details
data "azurerm_network_interface" "nics" {
  provider            = azurerm.adt
  for_each           = toset(local.clean_nic_names)
  name                = each.value
  resource_group_name = local.rg_name
}

# Import placeholder resources
resource "azurerm_windows_virtual_machine" "import" {
  provider            = azurerm.adt
  name                = local.vm_name
  resource_group_name = local.rg_name
  location            = data.azurerm_resource_group.target_rg.location
  size                = var.vm_size
  
  # These values will be updated during import
  admin_username      = "placeholder"
  admin_password      = "placeholder123!"
  
  network_interface_ids = [for nic in data.azurerm_network_interface.nics : nic.id]
  
  os_disk {
    caching              = try(data.azurerm_managed_disk.os_disk.disk_access_id != null, true) ? "ReadWrite" : "None"
    storage_account_type = try(data.azurerm_managed_disk.os_disk.storage_account_type, "Standard_LRS")
    name                 = local.os_disk_name
  }
  
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  
  lifecycle {
    ignore_changes = all
  }
}

# Network interface placeholders
resource "azurerm_network_interface" "import" {
  provider            = azurerm.adt
  for_each           = data.azurerm_network_interface.nics
  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  
  dynamic "ip_configuration" {
    for_each = each.value.ip_configuration
    content {
      name                          = ip_configuration.value.name
      subnet_id                     = ip_configuration.value.subnet_id
      private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
    }
  }
  
  lifecycle {
    ignore_changes = all
  }
}

# Data disk placeholders
resource "azurerm_managed_disk" "import" {
  provider             = azurerm.adt
  for_each             = local.data_disk_count > 0 ? data.azurerm_managed_disk.data_disks : {}
  name                 = each.value.name
  location             = each.value.location
  resource_group_name  = each.value.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb
  
  lifecycle {
    ignore_changes = all
  }
}

# VM data disk attachment placeholders
resource "azurerm_virtual_machine_data_disk_attachment" "import" {
  provider             = azurerm.adt
  for_each             = local.data_disk_count > 0 ? data.azurerm_managed_disk.data_disks : {}
  managed_disk_id      = azurerm_managed_disk.import[each.key].id
  virtual_machine_id   = azurerm_windows_virtual_machine.import.id
  lun                  = index(local.data_disk_names, each.key)
  caching              = "ReadWrite"
  
  lifecycle {
    ignore_changes = all
  }
}

# Output the import commands
output "vm_import_command" {
  value = "terraform import azurerm_windows_virtual_machine.import ${local.vm_id}"
}

output "nic_import_commands" {
  value = [for name, nic_id in local.nic_ids : 
    "terraform import 'azurerm_network_interface.import[\"${name}\"]' ${nic_id}"
  ]
}

output "data_disk_import_commands" {
  value = local.data_disk_count > 0 ? [for name, disk_id in local.data_disk_ids :
    "terraform import 'azurerm_managed_disk.import[\"${name}\"]' ${disk_id}"
  ] : []
}

output "data_disk_attachment_import_commands" {
  value = local.data_disk_count > 0 ? [for name, disk_id in local.data_disk_ids : 
    "terraform import 'azurerm_virtual_machine_data_disk_attachment.import[\"${name}\"]' ${azurerm_windows_virtual_machine.import.id}|${disk_id}|${index(local.data_disk_names, name)}"
  ] : []
} 