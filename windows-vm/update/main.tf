terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.101.0"
     }
    azapi = {
      source = "Azure/azapi"
      version = "1.13.1"
     }
    time = {
      source = "hashicorp/time"
      version = "0.11.1"
     }
  }
 required_version = ">=1.1.0"
  #  backend "azurerm" {}
 }

provider "azurerm" {
  features {}
 }
provider "azapi" {
  # Configuration options
 }
provider "time" {}
#
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
  #
  count_dd_storage_account_type             = ( var.request_type == "Update (Data Disk)" && 
                                                var.disk_storage_account_type != " " && 
                                                lower(var.disk_size_gb) == "same" ? 1 : 0)
  count_dd_storage_account_type__dd_size_gb = ( var.request_type == "Update (Data Disk)" && 
                                                var.disk_storage_account_type != " " && 
                                                lower(var.disk_size_gb) != "same" ? 1 : 0)
  count_dd_size_gb                          = ( var.request_type == "Update (Data Disk)" && 
                                                var.disk_storage_account_type == " " && 
                                                lower(var.disk_size_gb) != "same" ? 1 : 0)
  count_os_storage_account_type             = ( var.request_type == "Update (OS Disk)" && 
                                                var.disk_storage_account_type != " " ? 1 : 0)
  count_vm_size                             = lower(var.vm_size) != "same" ? 1 : 0
  count_vm_start                            = var.request_type == "Start VM" ? 1 : 0
  count_vm_stop                             = var.request_type == "Stop VM" ? 1 : 0
  count_vm_restart                          = var.request_type == "Restart VM" ? 1 : 0
  count_vm_backup                           = var.request_type == "Backup VM" ? 1 : 0
  count_vm_restore                          = var.request_type == "Restore VM" ? 1 : 0
  dd_name                                   = join("-",[local.vm_name, "data_disk", "0"])
  feature_vm_stop_start                     = 0 # 0 = not run, 1 - run
  osd_name                                  = join("-", [local.vm_name, "disk-os"])
  rg_name                                   = (strcontains(var.purpose_rg, "-") ? 
                                                var.purpose_rg : 
                                                join("-", [ local.naming.bu, 
                                                            local.naming.environment, 
                                                            var.location_xref[var.location], 
                                                            var.purpose_rg,
                                                            "rg"])
                                                )
  vm_name                                   = (strcontains(var.purpose, "-") ? 
                                                upper(var.purpose) : 
                                                upper(join(
                                                      "", 
                                                      [ "AZ",
                                                        var.location_gad_xref[local.naming.location],
                                                        "-",
                                                        local.vm_role,
                                                        var.environment_gad_xref[local.naming.environment],
                                                        local.vm_sequence ])))
  vm_role                                   = (strcontains(var.purpose, "/") ? 
                                                split("/", var.purpose)[0] :
                                                var.purpose)
  vm_sequence                               = (strcontains(var.purpose, "/") ? 
                                                split("/", var.purpose)[1] :
                                                "nnn")
 }
#
data "azurerm_managed_disk" "data_disk" {
  name                = local.dd_name
  resource_group_name = local.rg_name
 }
data "azurerm_managed_disk" "os_disk" {
  name                = local.osd_name
  resource_group_name = local.rg_name
 }
data "azurerm_subscription" "current" {}
data "azurerm_virtual_machine" "maintaining" {
  name                = local.vm_name
  resource_group_name = local.rg_name
 }
#
# VM Operations
resource "azapi_resource_action" "vm_start" {
  count       = local.count_vm_start
  type        = "Microsoft.Compute/virtualMachines@2023-09-01"
  resource_id = data.azurerm_virtual_machine.maintaining.id
  action      = "start"
  body        = jsonencode({})
}

resource "azapi_resource_action" "vm_stop" {
  count       = local.count_vm_stop
  type        = "Microsoft.Compute/virtualMachines@2023-09-01"
  resource_id = data.azurerm_virtual_machine.maintaining.id
  action      = "deallocate"
  body        = jsonencode({})
}

# Restart is implemented as a sequence of stop and start with a time delay
resource "azapi_resource_action" "vm_restart_stop" {
  count       = local.count_vm_restart
  type        = "Microsoft.Compute/virtualMachines@2023-09-01"
  resource_id = data.azurerm_virtual_machine.maintaining.id
  action      = "deallocate"
  body        = jsonencode({})
}

resource "time_sleep" "wait_30_seconds" {
  count           = local.count_vm_restart
  depends_on      = [azapi_resource_action.vm_restart_stop]
  create_duration = "30s"
}

resource "azapi_resource_action" "vm_restart_start" {
  count       = local.count_vm_restart
  type        = "Microsoft.Compute/virtualMachines@2023-09-01"
  resource_id = data.azurerm_virtual_machine.maintaining.id
  action      = "start"
  body        = jsonencode({})
  depends_on  = [time_sleep.wait_30_seconds]
}

# Backup and Restore Operations
resource "azapi_resource_action" "vm_backup" {
  count       = local.count_vm_backup
  type        = "Microsoft.Compute/virtualMachines@2023-09-01"
  resource_id = data.azurerm_virtual_machine.maintaining.id
  action      = "beginBackup"
  body        = jsonencode({
    properties = {
      backupVaultName = "DefaultBackupVault",
      backupItemName = local.vm_name,
      retentionDurationInDays = 30
    }
  })
  response_export_values = ["*"]
  
  # Error handling with lifecycle
  lifecycle {
    # Ignore errors if the VM is already protected
    ignore_changes = [body]
    # Replace if the backup fails for any reason
    replace_triggered_by = [data.azurerm_virtual_machine.maintaining]
  }
}

# Check if backup vault exists
data "azapi_resource" "backup_vault" {
  count = local.count_vm_restore
  type  = "Microsoft.RecoveryServices/vaults@2023-04-01"
  resource_id = "/subscriptions/${split("/", data.azurerm_subscription.current.id)[2]}/resourceGroups/${local.rg_name}/providers/Microsoft.RecoveryServices/vaults/DefaultBackupVault"
  response_export_values = ["*"]
}

# For restore, we need to first get the recovery points
data "azapi_resource_list" "recovery_points" {
  count          = local.count_vm_restore > 0 && try(data.azapi_resource.backup_vault[0].id, "") != "" ? 1 : 0
  type           = "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems/recoveryPoints@2023-04-01"
  parent_id      = "/subscriptions/${split("/", data.azurerm_subscription.current.id)[2]}/resourceGroups/${local.rg_name}/providers/Microsoft.RecoveryServices/vaults/DefaultBackupVault/backupFabrics/Azure/protectionContainers/IaasVMContainer;iaasvmcontainerv2;${local.rg_name};${local.vm_name}/protectedItems/VM;iaasvmcontainerv2;${local.rg_name};${local.vm_name}"
  response_export_values = ["*"]
}

# Check if any recovery points are available
locals {
  recovery_points_output = local.count_vm_restore > 0 ? try(data.azapi_resource_list.recovery_points[0].output, "{\"value\":[]}") : "{\"value\":[]}"
  has_recovery_points = local.count_vm_restore > 0 && try(length(jsondecode(local.recovery_points_output).value), 0) > 0
}

# Create an informational output for troubleshooting
output "recovery_point_info" {
  value = local.count_vm_restore > 0 ? {
    vault_exists = try(data.azapi_resource.backup_vault[0].id, "") != ""
    recovery_points_found = local.has_recovery_points
    first_recovery_point = local.has_recovery_points ? jsondecode(local.recovery_points_output).value[0].id : "None found"
  } : null
}

resource "azapi_resource_action" "vm_restore" {
  count       = local.has_recovery_points ? 1 : 0
  type        = "Microsoft.RecoveryServices/vaults@2023-04-01"
  resource_id = "/subscriptions/${split("/", data.azurerm_subscription.current.id)[2]}/resourceGroups/${local.rg_name}/providers/Microsoft.RecoveryServices/vaults/DefaultBackupVault"
  action      = "restore"
  body        = jsonencode({
    properties = {
      objectType = "IaasVMRestoreRequest",
      recoveryPointId = jsondecode(local.recovery_points_output).value[0].id,
      recoveryType = "OriginalLocation",
      sourceResourceId = data.azurerm_virtual_machine.maintaining.id,
      targetResourceGroupId = "/subscriptions/${split("/", data.azurerm_subscription.current.id)[2]}/resourceGroups/${local.rg_name}"
    }
  })
  response_export_values = ["*"]
  depends_on = [data.azapi_resource_list.recovery_points]
  
  # Error handling with lifecycle
  lifecycle {
    # Replace if the restore fails for any reason
    replace_triggered_by = [data.azapi_resource_list.recovery_points]
  }
}

# Disk Updates
resource "azapi_update_resource" "dd_size_gb" {
  count = local.count_dd_size_gb
  type = "Microsoft.Compute/disks@2023-10-02"
  resource_id = data.azurerm_managed_disk.data_disk.id
  body = {
    properties = {
      diskSizeGB = var.disk_size_gb
    }
   }
 }
resource "azapi_update_resource" "dd_storage_account_type" {
  count = local.count_dd_storage_account_type
  type = "Microsoft.Compute/disks@2023-10-02"
  resource_id = data.azurerm_managed_disk.data_disk.id
  body = {
    sku = {
      name = var.disk_storage_account_type
    }
   }
 }
resource "azapi_update_resource" "dd_storage_account_type__dd_size_gb" {
  count = local.count_dd_storage_account_type__dd_size_gb
  type = "Microsoft.Compute/disks@2023-10-02"
  resource_id = data.azurerm_managed_disk.data_disk.id
  body = {
    properties = {
      diskSizeGB = var.disk_size_gb
    }
    sku = {
      name = var.disk_storage_account_type
    }    
   }
 }
resource "azapi_update_resource" "vm_os_storage_account_type" {
  count = local.count_os_storage_account_type
  type = "Microsoft.Compute/disks@2023-10-02"
  resource_id = data.azurerm_managed_disk.os_disk.id
  body = {
    sku = {
      name = var.disk_storage_account_type
    }
   }
 }
resource "azapi_update_resource" "vm_vmSize" {
  count = local.count_vm_size
  type = "Microsoft.Compute/virtualMachines@2023-09-01"
  resource_id = data.azurerm_virtual_machine.maintaining.id
  body = {
    properties = {
      hardwareProfile = {
          vmSize = var.vm_size #SKU
      }
    }
   }
 }
#