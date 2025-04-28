terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.101.0"
      configuration_aliases = [ 
          azurerm.adt
       ]
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
  backend "azurerm" {}
 }

provider "azurerm" {
  features {}
 }

provider "azurerm" {
  alias                               = "adt"
  features {
    virtual_machine {
      delete_os_disk_on_deletion      = true
      graceful_shutdown               = false
      # skip_shutdown_and_force_delete  = false (Preview Feature)
    }
  }
 }

provider "azurerm" {
  alias                       = "uk_hub"
  skip_provider_registration  = true
  subscription_id             = "0c2f7215-bcfa-4e58-898b-4fe4d4673a37"
  features {}
 }

provider "azurerm" {
  alias                       = "us_hub"
  skip_provider_registration  = true
  subscription_id             = "74d15849-ba7b-4be6-8ba1-330a178ba88d"
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
  
  # VM Backup operations
  count_vm_backup_enable                    = var.request_type == "Enable VM Backup" ? 1 : 0
  count_vm_backup_disable                   = var.request_type == "Disable VM Backup" ? 1 : 0
  count_vm_backup_now                       = var.request_type == "Backup VM Now" ? 1 : 0
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
                                                
  # RSV related variables
  rsv_name                                  = var.recovery_vault_name
  rsv_resource_group                        = var.recovery_vault_rg
  backup_policy_id                          = var.backup_policy_id != "" ? var.backup_policy_id : try(data.azurerm_backup_policy_vm.policy[0].id, "")
 }
#
data "azurerm_managed_disk" "data_disk" {
  provider            = azurerm.adt
  name                = local.dd_name
  resource_group_name = local.rg_name
 }
data "azurerm_managed_disk" "os_disk" {
  provider            = azurerm.adt
  name                = local.osd_name
  resource_group_name = local.rg_name
 }
data "azurerm_subscription" "current" {
  provider = azurerm.adt
}
data "azurerm_virtual_machine" "maintaining" {
  provider            = azurerm.adt
  name                = local.vm_name
  resource_group_name = local.rg_name
 }

# Backup related data sources
data "azurerm_recovery_services_vault" "rsv" {
  count               = local.count_vm_backup_enable + local.count_vm_backup_disable + local.count_vm_backup_now + local.count_vm_restore
  name                = local.rsv_name
  resource_group_name = local.rsv_resource_group
}

data "azurerm_backup_policy_vm" "policy" {
  count               = local.count_vm_backup_enable
  name                = var.backup_policy_name
  recovery_vault_name = local.rsv_name
  resource_group_name = local.rsv_resource_group
}

# We'll use this to look up the protected VM details
data "azurerm_resources" "protected_vm" {
  count               = local.count_vm_backup_disable + local.count_vm_backup_now + local.count_vm_restore
  name                = local.vm_name
  resource_group_name = local.rsv_resource_group
  type                = "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems"
  required_tags       = {}
}

# References to modules used in the create process (to prevent orphan resources)
module "availability_set_main" {
  source = "../availability-set"
  providers = {
    azurerm.adt = azurerm.adt
  }
  location = local.naming.location
  naming = local.naming
  availability_set_data = []
}

module "managed_data_disk" {
  source = "../managed-disk"
  providers = {
    azurerm.adt = azurerm.adt
  }
  location = local.naming.location
  managed_disk_data = []
}

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

# Reference to original resources from create
# Instead of empty resources with count=0, we'll use the proper "import" block
# in actual usage to reference existing resources

# Empty placeholder for VM
resource "azurerm_windows_virtual_machine" "main" {
  provider = azurerm.adt
  for_each = {}
  name                = ""
  location            = ""
  resource_group_name = ""
  size                = ""
  admin_username      = ""
  admin_password      = ""
  network_interface_ids = []
  os_disk {
    caching           = ""
    storage_account_type = ""
  }
}

# Empty placeholder for NICs
resource "azurerm_network_interface" "nic1" {
  provider = azurerm.adt
  for_each = {}
  name                = ""
  location            = ""
  resource_group_name = ""
  ip_configuration {
    name                          = ""
    subnet_id                     = ""
    private_ip_address_allocation = ""
  }
}

resource "azurerm_network_interface" "nic2" {
  provider = azurerm.adt
  for_each = {}
  name                = ""
  location            = ""
  resource_group_name = ""
  ip_configuration {
    name                          = ""
    subnet_id                     = ""
    private_ip_address_allocation = ""
  }
}

# Empty placeholder for extensions
resource "azurerm_virtual_machine_extension" "custom_extensions" {
  provider = azurerm.adt
  for_each = {}
  name                 = ""
  virtual_machine_id   = ""
  publisher            = ""
  type                 = ""
  type_handler_version = ""
}

resource "azurerm_virtual_machine_extension" "domain_join" {
  provider = azurerm.adt
  for_each = {}
  name                 = ""
  virtual_machine_id   = ""
  publisher            = ""
  type                 = ""
  type_handler_version = ""
}

# Backup Operations
# Enable VM Backup
resource "azurerm_backup_protected_vm" "vm_backup" {
  count               = local.count_vm_backup_enable
  resource_group_name = local.rsv_resource_group
  recovery_vault_name = local.rsv_name
  source_vm_id        = data.azurerm_virtual_machine.maintaining.id
  backup_policy_id    = local.backup_policy_id
}

# Trigger backup now (on-demand backup)
resource "azapi_resource_action" "vm_backup_now" {
  count               = local.count_vm_backup_now
  type                = "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2023-04-01"
  resource_id         = data.azurerm_resources.protected_vm[0].resources[0].id
  action              = "backup"
  body                = jsonencode({
    properties = {
      expiryTimeUTC = timeadd(timestamp(), "168h") # 7 days expiry for on-demand backup
    }
  })
}

# Disable VM Backup
resource "azapi_resource_action" "vm_backup_disable" {
  count               = local.count_vm_backup_disable
  type                = "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2023-04-01"
  resource_id         = data.azurerm_resources.protected_vm[0].resources[0].id
  action              = "removeProtection"
  body                = jsonencode({
    properties = {
      deleteBackupData = true
    }
  })
}

# Restore VM
resource "azapi_resource_action" "vm_restore" {
  count               = local.count_vm_restore
  type                = "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2023-04-01"
  resource_id         = data.azurerm_resources.protected_vm[0].resources[0].id
  action              = "restore"
  body                = jsonencode({
    properties = {
      restoreRequestType           = "OriginalLocation",
      recoveryPointId              = var.recovery_point_id,
      sourceResourceId             = data.azurerm_virtual_machine.maintaining.id,
      originalStorageAccountOption = "Restore",
      originalNetworkingOption     = "Restore",
      useOriginalStorageAccount    = true,
      useOriginalNetworkConfig     = true
    }
  })
}

# Monitor restore operation (if needed to track progress)
resource "time_sleep" "wait_for_restore" {
  count           = local.count_vm_restore
  depends_on      = [azapi_resource_action.vm_restore]
  create_duration = "180s" # Wait for restore to initiate
}
#