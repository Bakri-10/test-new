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
    bu                        = lower(split("-", data.azurerm_subscription.current.display_name)[1])
    environment               = lower(split("-", data.azurerm_subscription.current.display_name)[2])
    environment_abbreviation  = (var.environment_abbr_xref[
                                lower(split("-", data.azurerm_subscription.current.display_name)[2])])
    loc_abbreviation          = var.location_xref[var.location]
    location                  = var.location
    region                    = lower(split("-", data.azurerm_subscription.current.display_name)[0])
    nn                        = lower(split("-", data.azurerm_subscription.current.display_name)[3])
    subscription_name         = data.azurerm_subscription.current.display_name
    subscription_id           = data.azurerm_subscription.current.id
   }
   
  # Import parameters
  vm_name                     = var.vm_name
  rg_name                     = var.resource_group_name
  vm_id                       = "${local.naming.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.Compute/virtualMachines/${local.vm_name}"
  
  # Collect NIC information - convert string input to number
  nic_count                   = tonumber(var.nic_count)
  nic_ids                     = [for i in range(1, local.nic_count + 1) : 
                                  "${local.naming.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.Network/networkInterfaces/${local.vm_name}-nic-${format("%02d", i)}"]
  
  # Collect disk information - convert string input to number
  os_disk_name                = "${local.vm_name}-disk-os"
  os_disk_id                  = "${local.naming.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.Compute/disks/${local.os_disk_name}"
  data_disk_count             = tonumber(var.data_disk_count)
  data_disk_ids               = [for i in range(0, local.data_disk_count) : 
                                  "${local.naming.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.Compute/disks/${local.vm_name}-data_disk-${i}"]
}

# Data sources
data "azurerm_subscription" "current" {}

# Get the resource group first to validate it exists
data "azurerm_resource_group" "target_rg" {
  provider = azurerm.adt
  name     = local.rg_name
}

# Get VM details using a more resilient approach
data "azurerm_virtual_machine" "existing" {
  provider            = azurerm.adt
  name                = local.vm_name
  resource_group_name = local.rg_name
}

# Get OS disk details if it exists
data "azurerm_managed_disk" "os_disk" {
  provider            = azurerm.adt
  count               = try(data.azurerm_virtual_machine.existing.id != "", 0) == 1 ? 1 : 0
  name                = local.os_disk_name
  resource_group_name = local.rg_name
}

# Get data disk details if they exist
data "azurerm_managed_disk" "data_disks" {
  provider            = azurerm.adt
  for_each           = try(data.azurerm_virtual_machine.existing.id != "", false) ? {
    for idx in range(local.data_disk_count) : tostring(idx) => idx
  } : {}
  name                = "${local.vm_name}-data_disk-${each.value}"
  resource_group_name = local.rg_name
}

# Get NIC details if they exist
data "azurerm_network_interface" "nics" {
  provider            = azurerm.adt
  for_each           = try(data.azurerm_virtual_machine.existing.id != "", false) ? {
    for idx in range(1, local.nic_count + 1) : tostring(idx) => idx
  } : {}
  name                = "${local.vm_name}-nic-${format("%02d", each.value)}"
  resource_group_name = local.rg_name
}

# Import placeholder resources
resource "azurerm_windows_virtual_machine" "import" {
  provider            = azurerm.adt
  name                = local.vm_name
  resource_group_name = local.rg_name
  location            = data.azurerm_resource_group.target_rg.location
  size                = try(data.azurerm_virtual_machine.existing.size, "Standard_D2s_v3")
  
  # These values will be updated during import
  admin_username      = "placeholder"
  admin_password      = "placeholder123!"
  
  # Use dynamic network interface IDs
  network_interface_ids = [
    for nic in data.azurerm_network_interface.nics : nic.id
  ]
  
  os_disk {
    caching              = try(data.azurerm_managed_disk.os_disk[0].disk_access_id != null, true) ? "ReadWrite" : "None"
    storage_account_type = try(data.azurerm_managed_disk.os_disk[0].storage_account_type, "Standard_LRS")
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

# Network interface placeholders with dynamic configuration
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

# Data disk placeholders with dynamic configuration
resource "azurerm_managed_disk" "import" {
  provider             = azurerm.adt
  for_each            = data.azurerm_managed_disk.data_disks
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

# VM data disk attachment placeholders with dynamic configuration
resource "azurerm_virtual_machine_data_disk_attachment" "import" {
  provider           = azurerm.adt
  for_each          = data.azurerm_managed_disk.data_disks
  managed_disk_id    = azurerm_managed_disk.import[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.import.id
  lun                = tonumber(each.key)
  caching            = "ReadWrite"
  
  lifecycle {
    ignore_changes = all
  }
}

# Output the import commands
output "vm_import_command" {
  value = "terraform import azurerm_windows_virtual_machine.import ${local.vm_id}"
}

output "nic_import_commands" {
  value = [for nic_id in local.nic_ids : 
    "terraform import 'azurerm_network_interface.import[\"${split("/", nic_id)[8]}\"]' ${nic_id}"
  ]
}

output "data_disk_import_commands" {
  value = [for disk_id in local.data_disk_ids :
    "terraform import 'azurerm_managed_disk.import[\"${split("/", disk_id)[8]}\"]' ${disk_id}"
  ]
}

output "data_disk_attachment_import_commands" {
  value = [for i in range(0, local.data_disk_count) : 
    "terraform import 'azurerm_virtual_machine_data_disk_attachment.import[\"${i}\"]' ${azurerm_windows_virtual_machine.import.id}|${local.data_disk_ids[i]}|${i}"
  ]
} 