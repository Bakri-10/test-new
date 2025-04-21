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

# Use azurerm_resources instead of azurerm_virtual_machine to get all VM details
data "azurerm_resources" "import_vm" {
  provider            = azurerm.adt
  name                = local.vm_name
  resource_group_name = local.rg_name
  type                = "Microsoft.Compute/virtualMachines"
  required_tags       = {}
}

data "azurerm_managed_disk" "os_disk" {
  provider            = azurerm.adt
  name                = local.os_disk_name
  resource_group_name = local.rg_name
}

data "azurerm_managed_disk" "data_disks" {
  provider            = azurerm.adt
  count               = local.data_disk_count
  name                = "${local.vm_name}-data_disk-${count.index}"
  resource_group_name = local.rg_name
}

data "azurerm_network_interface" "nics" {
  provider            = azurerm.adt
  count               = local.nic_count
  name                = "${local.vm_name}-nic-${format("%02d", count.index + 1)}"
  resource_group_name = local.rg_name
}

# Import placeholder resources
# The actual import will happen via the terraform import command in the workflow
resource "azurerm_windows_virtual_machine" "import" {
  provider            = azurerm.adt
  name                = local.vm_name
  resource_group_name = local.rg_name
  location            = try(data.azurerm_resources.import_vm.resources[0].location, var.location)
  size                = "Standard_D2s_v3" # Using a default size, will be overridden by import
  
  # These values will be updated during import but are required for the resource declaration
  admin_username      = "placeholder"
  admin_password      = "placeholder123!" # Must meet complexity requirements (placeholder only)
  
  # Use placeholder network interface IDs - these will be updated during import
  network_interface_ids = try(
    [for nic in data.azurerm_network_interface.nics : nic.id],
    ["/subscriptions/${local.naming.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.Network/networkInterfaces/${local.vm_name}-nic-01"]
  )
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = try(data.azurerm_managed_disk.os_disk.storage_account_type, "Standard_LRS")
    name                 = local.os_disk_name
  }
  
  # Placeholder source image reference - will be updated during import
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  
  # This resource is just a placeholder for the import command
  # The actual values will be populated once the import is complete
  lifecycle {
    ignore_changes = all
  }
}

# Network interface placeholders
resource "azurerm_network_interface" "import" {
  provider            = azurerm.adt
  count               = local.nic_count
  name                = data.azurerm_network_interface.nics[count.index].name
  location            = data.azurerm_network_interface.nics[count.index].location
  resource_group_name = data.azurerm_network_interface.nics[count.index].resource_group_name
  
  ip_configuration {
    name                          = "${local.vm_name}-ipconfig"
    subnet_id                     = data.azurerm_network_interface.nics[count.index].ip_configuration[0].subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  
  lifecycle {
    ignore_changes = all
  }
}

# Data disk placeholders
resource "azurerm_managed_disk" "import" {
  provider             = azurerm.adt
  count                = local.data_disk_count
  name                 = data.azurerm_managed_disk.data_disks[count.index].name
  location             = data.azurerm_managed_disk.data_disks[count.index].location
  resource_group_name  = data.azurerm_managed_disk.data_disks[count.index].resource_group_name
  storage_account_type = data.azurerm_managed_disk.data_disks[count.index].storage_account_type
  create_option        = "Empty"
  disk_size_gb         = data.azurerm_managed_disk.data_disks[count.index].disk_size_gb
  
  lifecycle {
    ignore_changes = all
  }
}

# VM data disk attachment placeholders
resource "azurerm_virtual_machine_data_disk_attachment" "import" {
  provider           = azurerm.adt
  count              = local.data_disk_count
  managed_disk_id    = azurerm_managed_disk.import[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.import.id
  lun                = count.index
  caching            = "ReadWrite"
  
  lifecycle {
    ignore_changes = all
  }
}

# Output the import commands for reference
output "vm_import_command" {
  value = "terraform import azurerm_windows_virtual_machine.import ${local.vm_id}"
}

output "nic_import_commands" {
  value = [for i, nic_id in local.nic_ids : "terraform import azurerm_network_interface.import[${i}] ${nic_id}"]
}

output "data_disk_import_commands" {
  value = [for i, disk_id in local.data_disk_ids : "terraform import azurerm_managed_disk.import[${i}] ${disk_id}"]
}

output "data_disk_attachment_import_commands" {
  value = [for i in range(0, local.data_disk_count) : "terraform import azurerm_virtual_machine_data_disk_attachment.import[${i}] ${azurerm_windows_virtual_machine.import.id}|${azurerm_managed_disk.import[i].id}|${i}"]
} 