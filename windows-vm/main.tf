terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.101.0"
      configuration_aliases = [ 
          azurerm.adt
       ]
     }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
     }
  }
 #required_version = ">=1.1.0"
   #backend "azurerm" {}
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
#
locals {
  #Strings
    string_one_data_disk                        = "==> Fail: Domain Join Requires a Single Disk"
    string_validation_passed                    = "==> Passed"
    string_15_char_limit                        = "==> Fail: Domain Join limits VM name to 15 characters"
  #Hub Storage Variables
    storage_account_hub     = lower(local.naming.region) == "us" ? "ngpdeus2securityst01" : "ngpdukssecurityst01"
    storage_account_hub_key = ((lower(local.naming.region) == "us") ?
                                  replace(((data.azurerm_storage_account.hub_us).primary_access_key), "\\", "\\\\")  : 
                                  replace(((data.azurerm_storage_account.hub_uk).primary_access_key), "\\", "\\\\") )
    storage_container_hub   = lower(local.naming.environment_abbreviation) == "prd" ? "prod" : "nonprod"
  #Custom Extensions
    file_uri_mde1         = join("", ["https://", local.storage_account_hub, ".blob.core.windows.net/", local.storage_container_hub, 
                                          "/Windows/Defender_Installation_and_Onboarding.bat"])
    file_uri_mde2         = join("", ["https://", local.storage_account_hub, ".blob.core.windows.net/", local.storage_container_hub, 
                                          "/Windows/Defender_Installer_Server_2012_R2_Server_2016.msi"])
    file_uri_mde3         = join("", ["https://", local.storage_account_hub, ".blob.core.windows.net/", local.storage_container_hub, 
                                          "/Windows/Defender_Onboarding_Script_Server_2012_R2_Server_2016.cmd"])
    file_uri_mde4         = join("", ["https://", local.storage_account_hub, ".blob.core.windows.net/", local.storage_container_hub, 
                                          "/Windows/Defender_Onboarding_Script_Server_2019_Server_2022.cmd"])
    file_uri_splunk1      = join("", ["https://", local.storage_account_hub, ".blob.core.windows.net/", local.storage_container_hub, 
                                          "/Windows/splunkufagents.zip"])
    file_uri_splunk2      = join("", ["https://", local.storage_account_hub, ".blob.core.windows.net/", local.storage_container_hub, 
                                          "/Windows/NG-SplunkUF-Config.zip"])
    file_uri_splunk3      = join("", ["https://", local.storage_account_hub, ".blob.core.windows.net/", local.storage_container_hub, 
                                          "/Windows/NG-SplunkUF-WDC-CNI-WinServer.bat"])
    file_uri_tanium       = join("", ["https://", local.storage_account_hub, ".blob.core.windows.net/", local.storage_container_hub, 
                                          "/Windows/Tanium_v2.zip"])
    #
    command_mde           = join("",[ "powershell.exe cd ", local.c2e_download, "; ",
                                "cmd.exe /c .\\Defender_Installation_and_Onboarding.bat; "
                                ])
    command_splunk        = join("",[ "powershell.exe cd ", local.c2e_download, "; ",
                                        "cmd.exe /c .\\NG-SplunkUF-WDC-CNI-WinServer.bat; "
                                        ])
    command_tanium        = join("",[ "powershell.exe cd ", local.c2e_download, "; ",
                                        "cmd.exe /c .\\7.4.10.1054_windows_SetupClient.exe ",
                                        "/ServerAddress=bil-tanos-001.na.ngrid.net,bil-tanos-002.na.ngrid.net,tsus2.nationalgrid.com,65.196.116.129,10.106.58.61,10.106.58.62 /S; ",
                                        ])
    #
    c2e_download          = "C:\\Packages\\Plugins\\Microsoft.Compute.CustomScriptExtension\\1.*\\Downloads\\0\\Windows"
    c2e_extensions        = replace(join("", [
                                "powershell.exe cd ", local.c2e_download, "; ",
                                "Expand-Archive -Path splunkufagents.zip -DestinationPath .; ", 
                                "Expand-Archive -Path NG-SplunkUF-Config.zip -DestinationPath .; ", 
                                "Expand-Archive -Path Tanium_v2.zip -DestinationPath .; ", 
                                local.command_splunk,
                                local.command_tanium,
                                local.command_mde,
                                "exit 0" 
                                ]),
                            "\\", #After string joined together, update the string submitted to handle the escape character
                            "\\\\")
  #Domain Join Variables
    dj_pre_prod_name  = "PREPROD.NATIONALGRID.COM"
    dj_pre_prod_user  = "GBL-SVC-SVRCLOUDJOIN@PREPROD.NATIONALGRID.COM"

    dj_prod_name      = "PROD.NATIONALGRID.COM"
    dj_prod_user      = "GBL-SVC-SVRCLOUDJOIN@PROD.NATIONALGRID.COM"

    dj_name           = local.naming.environment_abbreviation == "prd" || local.naming.environment_abbreviation == "pd" ? local.dj_prod_name : local.dj_pre_prod_name
    dj_user           = local.naming.environment_abbreviation == "prd" || local.naming.environment_abbreviation == "pd" ? local.dj_prod_user : local.dj_pre_prod_user

    dj_restart        = true
    dj_options        = 3

    dj_kv_id          = (lower(local.naming.region) == lower("US") ? 
                          "/subscriptions/74d15849-ba7b-4be6-8ba1-330a178ba88d/resourceGroups/ng-pd-eus2-keyvault-rg/providers/Microsoft.KeyVault/vaults/ng-prd-eus2-kv-01" :
                          "/subscriptions/0c2f7215-bcfa-4e58-898b-4fe4d4673a37/resourceGroups/ng-pd-uks-centralkeyvault-rg/providers/Microsoft.KeyVault/vaults/ng-prd-uks-kv-01")
    dj_secret_name    = (local.naming.environment_abbreviation == "prd" || local.naming.environment_abbreviation == "pd" ? 
                          "GBL-SVC-SVRCLOUDJOIN-Prod" : 
                          "GBL-SVC-SVRCLOUDJOIN-preProd")
    dj_password       = data.azurerm_key_vault_secret.dj_password.value

  #
  naming = {
    bu                        = (strcontains(var.purpose_rg, "/") ? 
                                  lower(split("/", var.purpose_rg)[0]) :
                                  lower(split("-", data.azurerm_subscription.current.display_name)[1]))
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
  admin_password = join("", [random_id.for_password.hex, "Ab1!"])
  count_uk = local.naming.region == "uk" ? 1 : 0
  count_us = local.naming.region == "us" ? 1 : 0
  #
  variables_map = tolist([local.variables_row])
  variables_row = merge({
      "request_type"                    = var.request_type,
      "vm_size"                         = var.vm_size,
      "purpose"                         = var.purpose,
      "purpose_rg"                      = lower(var.purpose_rg),
      "project_ou"                      = var.project_ou,
      "subnetname_wvm"                  = var.subnetname_wvm,
      "subnetname_wvm2"                  = var.subnetname_wvm2,
      "disk_size_gb"                    = var.disk_size_gb,
      "disk_storage_account_type"       = var.disk_storage_account_type,
      #
      "data_disk_count"                 = var.data_disk_count,
      "data_disk_size_gb"               = var.data_disk_size_gb,
      "data_disk_storage_account_type"  = var.data_disk_storage_account_type,
      "enable_automatic_updates"        = var.enable_automatic_updates,
      "eviction_policy"                 = var.eviction_policy,
      "image_reference_sku"             = var.image_reference_sku,
      "max_bid_price"                   = var.max_bid_price,
      "os_disk_caching"                 = var.os_disk_caching,
      "os_disk_size_gb"                 = var.os_disk_size_gb,
      "os_disk_storage_account_type"    = var.os_disk_storage_account_type,
      "priority"                        = var.priority,
      "timezone"                        = var.timezone_xref[var.location],
      "ultra_ssd_enabled"               = var.ultra_ssd_enabled,
      "unique_id"                       = "0",
      "zone"                            = var.zone
    }
   )
  #
  raw_csv_map = try(
                  csvdecode(file("../parameters.csv")) , 
                  local.variables_map
   )
  purpose_map = { 
    for row_id, inst in local.raw_csv_map :
      row_id => {
        purpose     = try(
                      (inst.purpose == "" ? 
                        local.variables_row.purpose : 
                        inst.purpose), 
                      local.variables_row.purpose
                    )
        purpose_rg  = lower(try(
                      (inst.purpose_rg == "" ? 
                        local.variables_row.purpose_rg : 
                        inst.purpose_rg), 
                      local.variables_row.purpose_rg
                    ))
    }
   }
  step_1_map  = {
    for row_id, inst in local.raw_csv_map :
      row_id => merge(local.raw_csv_map[row_id],
                      local.purpose_map[row_id])
   }
  #
  common_simple_map = { 
    for row_id, inst in local.step_1_map :
      row_id => {
        rg_name     = (strcontains(inst.purpose_rg, "-") ? 
                        inst.purpose_rg : 
                        strcontains(inst.purpose_rg, "/") ?
                        join("-", [ local.naming.bu, 
                                    local.naming.environment, 
                                    var.location_xref[var.location], 
                                    split("/", inst.purpose_rg)[1],
                                    "rg"]) :
                        join("-", [ local.naming.bu, 
                                    local.naming.environment, 
                                    var.location_xref[var.location], 
                                    inst.purpose_rg,
                                    "rg"])
                        )
        vnet_name   = join("-", [ local.naming.bu, 
                                  local.naming.environment, 
                                  var.location_xref[var.location], 
                                  "vnet", 
                                  local.naming.nn])
        vnet_rg     = join("-", [ local.naming.bu, 
                                  local.naming.environment, 
                                  var.location_xref[var.location], 
                                  "spokenetwork-rg"])
    }
   }
  common_dependent_map = {
    for row_id, inst in local.common_simple_map :
      row_id => {
        vnet_id = join("/", [ local.naming.subscription_id, 
                              "resourceGroups", 
                              inst.vnet_rg, 
                              "providers",
                              "Microsoft.Network/virtualNetworks",
                              inst.vnet_name])
    }
   }
  step_2_map  = {
    for row_id, inst in local.step_1_map :
      row_id => merge(local.step_1_map[row_id],
                      local.common_simple_map[row_id],
                      local.common_dependent_map[row_id])
   }
  #
  module_simple_map = { 
    for row_id, inst in local.step_2_map :
      row_id => {
        data_disk_count                 = try(
                                            (inst.data_disk_count == "" ? 
                                              local.variables_row.data_disk_count : 
                                              inst.data_disk_count), 
                                            local.variables_row.data_disk_count
                                          ),
        data_disk_size_gb               = try(
                                          (inst.data_disk_size_gb == "" ? 
                                            local.variables_row.disk_size_gb : 
                                            inst.data_disk_size_gb), 
                                          local.variables_row.disk_size_gb
                                          ),
        data_disk_storage_account_type  = try(
                                            (inst.data_disk_storage_account_type == "" ? 
                                              local.variables_row.disk_storage_account_type : 
                                              inst.data_disk_storage_account_type), 
                                            local.variables_row.disk_storage_account_type
                                          )
        disk_size_gb                    = try(
                                          (inst.disk_size_gb == "" ? 
                                            local.variables_row.disk_size_gb : 
                                            inst.disk_size_gb), 
                                          local.variables_row.disk_size_gb
                                          ),
        disk_storage_account_type       = try(
                                            (inst.disk_storage_account_type == "" ? 
                                              local.variables_row.disk_storage_account_type : 
                                              inst.disk_storage_account_type), 
                                            local.variables_row.disk_storage_account_type
                                          )
        enable_automatic_updates        = try(
                                            (inst.enable_automatic_updates == "" ? 
                                              tobool(lower(local.variables_row.enable_automatic_updates)) : 
                                              tobool(lower(inst.enable_automatic_updates))), 
                                            tobool(lower(local.variables_row.enable_automatic_updates))
                                          )
        eviction_policy                 = try(
                                            (inst.eviction_policy == "" ? 
                                              local.variables_row.eviction_policy : 
                                              contains(var.valid_eviction_policies, inst.eviction_policy) ?
                                                inst.eviction_policy :
                                                local.variables_row.eviction_policy), 
                                            local.variables_row.eviction_policy
                                          )
        image_reference_sku             = try(
                                            (inst.image_reference_sku == "" ? 
                                              local.variables_row.image_reference_sku : 
                                              contains(var.valid_image_reference_skus, inst.image_reference_sku) ?
                                                inst.image_reference_sku :
                                                local.variables_row.image_reference_sku), 
                                            local.variables_row.image_reference_sku
                                          )
        max_bid_price                   = try(
                                            (inst.max_bid_price == "" ? 
                                              tonumber(local.variables_row.max_bid_price) : 
                                              tonumber(inst.max_bid_price)), 
                                            tonumber(local.variables_row.max_bid_price)
                                          )
        os_disk_caching                 = try(
                                            (inst.os_disk_caching == "" ? 
                                              local.variables_row.os_disk_caching : 
                                              contains(var.valid_os_disk_caching_types, inst.os_disk_caching) ?
                                                inst.os_disk_caching :
                                                local.variables_row.os_disk_caching), 
                                            local.variables_row.os_disk_caching
                                          )
        os_disk_size_gb                 = try(
                                            (inst.os_disk_size_gb == "" ? 
                                              tonumber(local.variables_row.os_disk_size_gb) : 
                                              tonumber(inst.os_disk_size_gb)), 
                                            tonumber(local.variables_row.os_disk_size_gb)
                                          )
        os_disk_storage_account_type    = try(
                                            (inst.os_disk_storage_account_type == "" ? 
                                              local.variables_row.os_disk_storage_account_type : 
                                              contains(var.valid_os_storage_account_types, inst.os_disk_storage_account_type) ?
                                                inst.os_storage_account_type :
                                                local.variables_row.os_storage_account_type), 
                                            local.variables_row.os_disk_storage_account_type
                                          )
        priority                        = try(
                                            (inst.priority == "" ? 
                                              local.variables_row.priority : 
                                              contains(var.valid_priorities, inst.priority) ?
                                                inst.priority :
                                                local.variables_row.priority), 
                                            local.variables_row.priority
                                          )
        project_ou                      = try(
                                            (inst.project_ou == "" ? 
                                              local.variables_row.project_ou : 
                                              inst.project_ou), 
                                            local.variables_row.project_ou
                                          )
        request_type                    = try(
                                            (inst.request_type == "" ? 
                                              local.variables_row.request_type : 
                                              inst.request_type),
                                            local.variables_row.request_type
                                          )
        subnetname_wvm                  = try(
                                            (inst.subnetname_wvm == "" ? 
                                              local.variables_row.subnetname_wvm : 
                                              inst.subnetname_wvm),
                                            local.variables_row.subnetname_wvm
                                          )
        subnetname_wvm2                  = try(
                                            (inst.subnetname_wvm2 == "" ? 
                                              local.variables_row.subnetname_wvm2 : 
                                              inst.subnetname_wvm2),
                                            local.variables_row.subnetname_wvm2
                                          )
        timezone                        = try(
                                            (inst.timezone == "" ? 
                                              local.variables_row.timezone : 
                                              inst.timezone), 
                                            local.variables_row.timezone
                                          )
        ultra_ssd_enabled               = try(
                                            (inst.ultra_ssd_enabled == "" ? 
                                              tobool(lower(local.variables_row.ultra_ssd_enabled)) : 
                                              tobool(lower(inst.ultra_ssd_enabled))), 
                                            tobool(lower(local.variables_row.ultra_ssd_enabled))
                                          )
        unique_id                       = try(
                                            (inst.unique_id == "" ? 
                                              local.variables_row.unique_id : 
                                              inst.unique_id), 
                                            local.variables_row.unique_id
                                          )
        
         vm_role                         = (strcontains(inst.purpose, "/") ? 
                                            split("/", inst.purpose)[0] :
                                            "defined")                                                                              
        vm_sequence                     = (strcontains(inst.purpose, "/") ? 
                                            split("/", inst.purpose)[1] :
                                            random_integer.for_name.result)
        vm_size                         = try(
                                            (inst.vm_size == "" ? 
                                              local.variables_row.vm_size : 
                                              inst.vm_size), 
                                            local.variables_row.vm_size
                                          )
        zone                            = try(
                                            (inst.zone == "" ? 
                                              local.variables_row.zone : 
                                              inst.zone), 
                                            local.variables_row.zone
                                          )
    }
   }
  module_dependent1_map = { 
    for row_id, inst in local.step_2_map :
      row_id => {
        availability_set_name       = join("-", [
                                          local.naming.bu,
                                          local.naming.environment,
                                          local.naming.loc_abbreviation,
                                          join(".", [ local.module_simple_map[row_id].vm_role,
                                                      local.module_simple_map[row_id].vm_sequence]),
                                          "avail",
                                          local.naming.nn]
                                      )
        domain_join_ou              = (local.naming.environment_abbreviation == "prd" || local.naming.environment_abbreviation == "pd" ? 
                                            join("",[ "OU=", 
                                                    local.module_simple_map[row_id].project_ou, 
                                                    ",OU=AZURE 2.0,OU=TIER 1 SERVERS,OU=STAGING,DC=PROD,DC=NATIONALGRID,DC=COM"])   : 
                                            join("",[ "OU=", 
                                                    local.module_simple_map[row_id].project_ou, 
                                                    ",OU=AZURE 2.0,OU=TIER 1 SERVERS,OU=STAGING,DC=PREPROD,DC=NATIONALGRID,DC=COM"]))
        vm_name                     = (strcontains(inst.purpose, "-") ? 
                                        upper(inst.purpose) : 
                                        upper(join("", [  "AZ",
                                                    var.location_gad_xref[local.naming.location],
                                                    "-",
                                                    local.module_simple_map[row_id].vm_role,
                                                    var.environment_gad_xref[local.naming.environment],
                                                    local.module_simple_map[row_id].vm_sequence ]))
                                        )
    }
   }
  module_dependent2_map = { 
    for row_id, inst in local.module_dependent1_map :
      row_id => {
        nic_name_1           = join("-", [inst.vm_name, "nic-01"]) 
        nic_name_2           = join("-", [inst.vm_name, "nic-02"])
        virtual_machine_id  = join("/", [ local.naming.subscription_id,
                                  "resourceGroups",
                                  local.common_simple_map[row_id].rg_name,
                                  "providers",
                                  "Microsoft.Compute/virtualMachines",
                                  inst.vm_name
                                  ])
      }
   }
  module_dependent3_map = { 
    for row_id, inst in local.module_dependent2_map :
      row_id => {
        nic_id_1       = join("/", [
                      local.naming.subscription_id,
                      "resourceGroups",
                      local.common_simple_map[row_id].rg_name,
                      "providers",
                      "Microsoft.Network/networkInterfaces",
                      inst.nic_name_1
                    ])
        nic_id_2       = join("/", [
                      local.naming.subscription_id,
                      "resourceGroups",
                      local.common_simple_map[row_id].rg_name,
                      "providers",
                      "Microsoft.Network/networkInterfaces",
                      inst.nic_name_2
                    ])
    }
   }
  step_3_map = {
    for row_id, inst in local.step_2_map :
      row_id => merge(local.step_2_map[row_id],
                      local.module_simple_map[row_id],
                      local.module_dependent1_map[row_id],
                      local.module_dependent2_map[row_id],
                      local.module_dependent3_map[row_id])
   }
  #
  subnet_nic_map = {
  for row_id, inst in data.azurerm_subnet.nic1 : row_id => {  
    nic_subnet_id_1      = inst.id
    nic_subnet_nsg_id_1  = inst.network_security_group_id
    nic_subnet_rt_id_1   = inst.route_table_id
    nic_subnet_prefix_1  = inst.address_prefixes[0]
    nic_subnet_start_1   = split("/", inst.address_prefixes[0])[0]
    nic_subnet_cidr_1    = split("/", inst.address_prefixes[0])[1]
  }
}

subnet_nic2_map = {
  for row_id, inst in data.azurerm_subnet.nic2 : row_id => {  
    nic_subnet_id_2      = inst.id
    nic_subnet_nsg_id_2  = inst.network_security_group_id
    nic_subnet_rt_id_2   = inst.route_table_id
    nic_subnet_prefix_2  = inst.address_prefixes[0]
    nic_subnet_start_2   = split("/", inst.address_prefixes[0])[0]
    nic_subnet_cidr_2    = split("/", inst.address_prefixes[0])[1]
  }
}
  feature_map = {
  for row_id, inst in data.azurerm_subnet.nic1 : row_id => {
    
  }
}

  feature_map_2 = {
  for row_id, inst in data.azurerm_subnet.nic2 : row_id => {
   
  }
}
  final_parms_map = {
  for row_id, inst in local.step_3_map :
  row_id => merge(
    local.step_3_map[row_id],
    local.subnet_nic_map[row_id],
    local.subnet_nic2_map[row_id],
    local.feature_map[row_id],
    local.feature_map_2[row_id]
  )
}
  #
  validation_map = {
    for row_id, inst in local.final_parms_map :
      row_id => {
        state = (
                  local.string_validation_passed)
      }
   }  
 }
#
data "azurerm_key_vault_secret" "dj_password" {
  provider      = azurerm.us_hub
  name          = local.dj_secret_name
  key_vault_id  = local.dj_kv_id
 }
data "azurerm_storage_account" "hub_uk" {
  provider            = azurerm.uk_hub
  name                = "ngpdukssecurityst01"
  resource_group_name = "ng-pd-uks-hubnetwork-rg"
 }
data "azurerm_storage_account" "hub_us" {
  provider            = azurerm.us_hub
  name                = "ngpdeus2securityst01"
  resource_group_name = "ng-pd-eus2-hubnetwork-rg"
 }
data "azurerm_subscription" "current" {
  provider = azurerm.adt
 }
data "azurerm_subnet" "nic1" {
  provider = azurerm.adt
  for_each = { for row_id, inst in local.step_3_map : row_id => inst }
    name                 = (each.value).subnetname_wvm
    virtual_network_name = (each.value).vnet_name
    resource_group_name  = (each.value).vnet_rg
 }
data "azurerm_subnet" "nic2" {
  provider = azurerm.adt
  for_each = { for row_id, inst in local.step_3_map : row_id => inst }
  name                 = (each.value).subnetname_wvm2  
  virtual_network_name = (each.value).vnet_name
  resource_group_name  = (each.value).vnet_rg
}
#
module "availability_set_main" {
  providers                       = { azurerm.adt = azurerm.adt }
  source                          = "../availability-set"
  location                        = local.naming.location
  naming                          = local.naming
  availability_set_data  = [for row_id, inst in local.final_parms_map : {
    availability_set_name         = local.final_parms_map[row_id].availability_set_name
    do_update                     = true
    platform_fault_domain_count   = "2"
    platform_update_domain_count  = "5"
    proximity_placement_group_id  = ""
    purpose                       = local.final_parms_map[row_id].purpose
    purpose_rg                    = local.final_parms_map[row_id].purpose_rg
  }]
 }
module "managed_data_disk" {
  providers         = { azurerm.adt = azurerm.adt }
  source            = "../managed-disk"
  location          = local.naming.location
  managed_disk_data = [for row_id, inst in local.final_parms_map : {
    disk_count            = (local.validation_map[row_id].state == local.string_validation_passed ?
                                local.final_parms_map [row_id].data_disk_count : "0" )
    disk_size_gb          = local.final_parms_map [row_id].data_disk_size_gb
    parent_name           = local.final_parms_map [row_id].vm_name
    resource_group_name   = local.final_parms_map [row_id].rg_name
    storage_account_type  = local.final_parms_map [row_id].data_disk_storage_account_type
    virtual_machine_id    = (azurerm_windows_virtual_machine.main)[row_id].id
  }]
 }
#
resource "azurerm_network_interface" "nic1" {
  provider = azurerm.adt
  for_each = { for row_id, inst in local.final_parms_map : row_id => inst }
  location            = local.naming.location
  name                = (each.value).nic_name_1
  resource_group_name = (each.value).rg_name

  ip_configuration {
    name                          = join("-", [(each.value).vm_name, "nic1_config" ])
    subnet_id                     = data.azurerm_subnet.nic1[each.key].id 
    private_ip_address_allocation = "Dynamic"
  }
}
#
resource "azurerm_network_interface" "nic2" {
  provider = azurerm.adt
  for_each = { for row_id, inst in local.final_parms_map : row_id => inst }
  location            = local.naming.location
  name                = (each.value).nic_name_2
  resource_group_name = (each.value).rg_name

  ip_configuration {
    name                          = join("-", [(each.value).vm_name, "nic2_config" ])
    subnet_id                     = data.azurerm_subnet.nic2[each.key].id  
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_virtual_machine_extension" "custom_extensions" {
  provider = azurerm.adt
  for_each = { for row_id, inst in local.final_parms_map : row_id => inst 
                if local.validation_map[row_id].state == local.string_validation_passed}
  depends_on  = [ azurerm_windows_virtual_machine.main,
                  module.managed_data_disk ]
  #Required
    name                       = join("-", [(each.value).vm_name, "MDE_Splunk_Tanium"])
    publisher                  = "Microsoft.Compute"
    type                       = "CustomScriptExtension"
    virtual_machine_id         = (each.value).virtual_machine_id

  #Optional
    auto_upgrade_minor_version = true
    protected_settings = <<-EOSETTINGS
      {
        "fileUris": [
            "${local.file_uri_mde1}",
            "${local.file_uri_mde2}",
            "${local.file_uri_mde3}",
            "${local.file_uri_mde4}",
            "${local.file_uri_splunk1}",
            "${local.file_uri_splunk2}",
            "${local.file_uri_splunk3}",
            "${local.file_uri_tanium}"
        ],
          "storageAccountName": "${local.storage_account_hub}",
          "storageAccountKey":  "${local.storage_account_hub_key}",
          "commandToExecute":   "${local.c2e_extensions}"
      }
    EOSETTINGS
    type_handler_version       = "1.8"
 }
resource "azurerm_virtual_machine_extension" "domain_join" {
  provider = azurerm.adt
  for_each = { for row_id, inst in local.final_parms_map : row_id => inst 
                if local.validation_map[row_id].state == local.string_validation_passed}
  depends_on  = [ azurerm_windows_virtual_machine.main,
                  module.managed_data_disk,
                  azurerm_virtual_machine_extension.custom_extensions ]
  #Required
    name                       = join("-", [(each.value).vm_name, "DomainJoin"])
    publisher                  = "Microsoft.Compute"
    type                       = "JsonADDomainExtension"
    virtual_machine_id         = (each.value).virtual_machine_id
  #Optional
    auto_upgrade_minor_version = true
    protected_settings = <<-EOSETTINGS
      {
        "Password": "${local.dj_password}"
      }
      EOSETTINGS
    settings = <<-EOSETTINGS
      {
        "Name":     "${local.dj_name}",
        "User":     "${local.dj_user}",
        "OUPath":   "${(each.value).domain_join_ou}",
        "Restart":  "${local.dj_restart}",
        "Options":  "${local.dj_options}"
      }
      EOSETTINGS
    type_handler_version       = "1.3"
 }
resource "azurerm_windows_virtual_machine" "main" {
  provider = azurerm.adt
  for_each = { for row_id, inst in local.final_parms_map : row_id => inst }
  depends_on = [
    module.availability_set_main,
    azurerm_network_interface.nic1,
    azurerm_network_interface.nic2
  ]
  #Required Arguments
    admin_password        = local.admin_password
    admin_username        = "vmadmin"
    location              = local.naming.location
    name                  = (local.validation_map[each.key].state == local.string_validation_passed ? 
                              (each.value).vm_name : 
                              local.validation_map[each.key].state) # input_validation error will show 
    network_interface_ids = [ (each.value).nic_id_1,(each.value).nic_id_2 ]
    resource_group_name   = (each.value).rg_name
    size                  = (each.value).vm_size
  #Optional Arguments
    availability_set_id         = module.availability_set_main.availability_set_id[each.key]
    enable_automatic_updates    = (each.value).enable_automatic_updates
    encryption_at_host_enabled  = false #true
    eviction_policy             = ((each.value).priority == "Spot"           ? 
                                    (each.value).eviction_policy : null)
    extensions_time_budget      = "PT1H30M"
    max_bid_price               = ((each.value).priority == "Spot"           ? 
                                    (each.value).max_bid_price : null)
    priority                    = (each.value).priority
    timezone                    = (each.value).timezone
    zone                        = ((each.value).zone != ""                   ? 
                                    (each.value).zone : null)

  dynamic "additional_capabilities" {
    for_each = (each.value).ultra_ssd_enabled == true ? [1] : []
    content {
      ultra_ssd_enabled = (each.value).ultra_ssd_enabled
    }
   }
  os_disk {
    # Required
      caching               = (each.value).os_disk_caching
      storage_account_type  = (each.value).os_disk_storage_account_type
    # Optional
      disk_size_gb          = ((each.value).os_disk_size_gb <= 128 ?
                                null :
                                (each.value).os_disk_size_gb)
      # Disk names include -01 suffix to match the actual Azure disk naming convention
      name                  = join("-", [(each.value).vm_name, "disk-os-01"])
   }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = (each.value).image_reference_sku
    version   = "latest"
   }
 }

# resource "azurerm_lb_backend_address_pool_association" "VM_to_LB" {
#   loadbalancer_backend_address_pool_id = var.loadbalancer_id
#   virtual_network_id = azurerm_network_interface.nic1[each.key].id
# }
resource "random_id" "for_password" {
  keepers = {
    time = "${timestamp()}"
  } 
  byte_length = 8
 }
resource "random_integer" "for_name" {
  min = 100
  max = 999
  keepers = {
    time = "${timestamp()}"
  } 
 }