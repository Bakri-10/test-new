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