provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    # Backend configuration will be provided via CLI arguments
  }
}

data "azurerm_subscription" "current" {}  // read the current subscription info

data "azurerm_client_config" "clientconfig" {} // read the current client config

locals {
  get_data = csvdecode(file("../parameters.csv"))
 // define data for naming standards 
  purpose_parts = split("/", var.purpose)
  purpose = length(local.purpose_parts) > 0 ? local.purpose_parts[0] : "default"
  sequence = length(local.purpose_parts) > 1 ? local.purpose_parts[1] : "01"
  
  naming = {
    bu = lower(split("-", data.azurerm_subscription.current.display_name)[1])  // read app/bu from the subscription data block
    environment = lower(split("-", data.azurerm_subscription.current.display_name)[2])  // read environment from subscription data block
    locations = var.location
    secondary_location = var.secondary_location
    nn = lower(split("-", data.azurerm_subscription.current.display_name)[3])  }
  env_location = {
    env_abbreviation       = var.environment_map[local.naming.environment]
    locations_abbreviation = var.location_map[local.naming.locations]
    secondary_location_abbreviation = var.location_map[local.naming.secondary_location]
      }
  # vnet_name = {
  #   for index, inst in local.get_data : index => inst {
  #     vnet_name = (lookup(inst, "vnet_name", null) != null && lookup(inst, "vnet_name", "") != "") ? inst.vnet_name : join("-", [local.naming.bu, local.naming.environment, local.naming_map.location_abbreviation[unique_id].location_abbreviation, "vnet", local.naming.nn])
  #     vnet_rg   = (lookup(inst, "vnet_resource_group", null) != null && lookup(inst, "vnet_resource_group", "") != "") ? inst.vnet_resource_group : join("-", [local.naming.bu, local.naming.environment, local.naming_map.location_abbreviation[unique_id].location_abbreviation, "spokenetwork-rg"])
  #   }

  # }
}

data "azurerm_resource_group" "rg" {
  for_each = { for inst in local.get_data : inst.unique_id => inst }
  name     = join("-", [local.naming.bu, local.naming.environment, local.env_location.locations_abbreviation, var.purpose_rg, "rg"])
}

output "resource_group_name" {
  value = data.azurerm_resource_group.rg
}

data "azurerm_virtual_network" "vnet" {
  for_each = { for inst in local.get_data : inst.unique_id => inst }
   name = (lookup(each.value, "vnet_name", null) != null && lookup(each.value, "vnet_name", "") != "") ? each.value.vnet_name : join("-", [local.naming.bu, local.naming.environment, local.env_location.locations_abbreviation, "vnet", local.naming.nn])
   resource_group_name  = (lookup(each.value, "vnet_resource_group", null) != null && lookup(each.value, "vnet_resource_group", "") != "") ? each.value.vnet_resource_group : join("-", [local.naming.bu, local.naming.environment, local.env_location.locations_abbreviation, "spokenetwork-rg"])
}
output "virtual_network_id" {
  value = data.azurerm_virtual_network.vnet
  sensitive = true
}

data "azurerm_subnet" "subnet" {
  for_each = { for inst in local.get_data : inst.unique_id => inst }
  name                 = (lookup(each.value, "subnet_name", null) != null && lookup(each.value, "subnet_name", "") != "") ? each.value.subnet_name : var.subnetname //lz<app>-<env>-<region>-<purpose>-snet-<nn>
  virtual_network_name = data.azurerm_virtual_network.vnet[each.key].name
  resource_group_name  = (lookup(each.value, "vnet_resource_group", null) != null && lookup(each.value, "vnet_resource_group", "") != "") ? each.value.vnet_resource_group : join("-", [local.naming.bu, local.naming.environment, local.env_location.locations_abbreviation, "spokenetwork-rg"])
}

output "subnet_id" {
  value = data.azurerm_subnet.subnet
  sensitive = true
}

resource "azurerm_mssql_server" "mssqlserver" {
  for_each = { for inst in local.get_data : inst.unique_id => inst }
   //<bu>-<env>-<region>-<purpose>-sql-<nn>
  name                         = join("", [local.naming.bu, "-", local.naming.environment, "-", local.env_location.locations_abbreviation, "-", local.purpose, "-sql-", local.sequence]) 
  resource_group_name          = data.azurerm_resource_group.rg[each.key].name
  location                     = var.location
  version                      = var.dbserverversion
  #  administrator_login          = data.azurerm_subscription.current.display_name
  #  administrator_login_password = random_password.randompassword.result
  minimum_tls_version          = var.tlsversion
 public_network_access_enabled = false 
  azuread_administrator {
    azuread_authentication_only = true
    login_username = data.azurerm_subscription.current.display_name
    object_id      = data.azurerm_client_config.clientconfig.object_id
  }

  # identity {
  #   type         = "UserAssigned"
  #   identity_ids = [azurerm_user_assigned_identity.UserAssigned[each.key].id]
  # }
}

# resource "azurerm_mysql_active_directory_administrator" "adadmin" {
#   for_each = { for inst in local.get_data : inst.unique_id => inst }
#   server_name         = azurerm_mssql_server.mssqlserver[each.key].name
#   resource_group_name = (lookup(each.value,"RGname",null) != null && lookup(each.value,"RGname","") != "" && var.RGname!="") ? each.value.RGname : data.azurerm_resource_group.rg[each.key].name
#   login               = data.azurerm_subscription.current.display_name
#   tenant_id           = data.azurerm_client_config.clientconfig.tenant_id
#   object_id           = data.azurerm_client_config.clientconfig.object_id
#   depends_on = [ azurerm_mssql_server.mssqlserver ]
# }

resource "azurerm_user_assigned_identity" "UserAssigned" {
  for_each = { for inst in local.get_data : inst.unique_id => inst }

  location            = var.location
  name                = join("", [local.naming.bu, "-", local.naming.environment, "-", local.env_location.locations_abbreviation, "-", local.purpose, "-admin"]) 
  resource_group_name = data.azurerm_resource_group.rg[each.key].name
}

# Set the TDE option with azure managed keys

resource "azurerm_mssql_server_transparent_data_encryption" "tde" {
  for_each = { for inst in local.get_data : inst.unique_id => inst }
  server_id = azurerm_mssql_server.mssqlserver[each.key].id
  auto_rotation_enabled = true
}

# enable the traffic between sql server and subnet

# resource "azurerm_mssql_virtual_network_rule" "networkrule" {
#   for_each = { for inst in local.get_data : inst.unique_id => inst }
#   name      = "sql-vnet-rule"
#   server_id = azurerm_mssql_server.mssqlserver[each.key].id 
#   subnet_id =  data.azurerm_subnet.subnet[each.key].id

#   depends_on = [ azurerm_mssql_server.mssqlserver  ]
# }


# resource "random_password" "randompassword" {
#  length = 16
#  special = true
#  override_special = "!#$%&*()-_=+[]{}<>:?"
# }

# output "random_pwd" {

#   value = random_password.randompassword
#   sensitive = true
# }

# resource "random_id" "randomnumber" {
#   keepers = {
#     # time = "${timestamp()}"
#     min = 00
#     max = 99
#   } 
#   byte_length = 1
# }

//***************** Create database *************

#resource "azurerm_mssql_database" "sqldb" {
#  for_each = { for inst in local.get_data : inst.unique_id => inst }
#  name           = join("", [local.naming.bu, "-", local.naming.environment, "-", local.env_location.locations_abbreviation, "-", local.purpose, "-sqldb-",random_id.randomnumber.hex]) 
#  server_id      = azurerm_mssql_server.mssqlserver[each.key].id
#  collation      = var.collation//"SQL_Latin1_General_CP1_CI_AS"
#  license_type   = "LicenseIncluded"
#  # max_size_gb    = 4
#  # read_scale     = true
#  sku_name       = var.skuname
#  zone_redundant = var.zoneredundancy
#depends_on = [ azurerm_mssql_server.mssqlserver ]
#}


//****************** Failover group Creation/Configuration ********************
//****************** First create secondary database ************************

// Add a new data source for secondary resource group
data "azurerm_resource_group" "secondary_rg" {
  for_each = { for inst in local.get_data : inst.unique_id => inst }
  name     = join("-", [local.naming.bu, local.naming.environment, local.env_location.secondary_location_abbreviation, var.purpose_rg, "rg"])
}

// Update the secondary server to use the secondary resource group
resource "azurerm_mssql_server" "mssqlserversecondary" {
  for_each = { for inst in local.get_data : inst.unique_id => inst }
  name                         = join("", [local.naming.bu, "-", local.naming.environment, "-", local.env_location.secondary_location_abbreviation, "-", local.purpose, "-sql-", local.sequence])
  resource_group_name          = data.azurerm_resource_group.secondary_rg[each.key].name  // Changed to use secondary RG
  location                     = var.secondary_location
  version                      = var.dbserverversion
  minimum_tls_version         = var.tlsversion
  public_network_access_enabled = false
  
  azuread_administrator {
    azuread_authentication_only = true
    login_username = data.azurerm_subscription.current.display_name
    object_id      = data.azurerm_client_config.clientconfig.object_id
  }
}

# ****************************** Create Private End point ********************

resource "azurerm_private_endpoint" "privateendpoint" {
  for_each = { for inst in local.get_data : inst.unique_id => inst }
  name                = join("", [local.naming.bu, "-", local.naming.environment, "-", local.env_location.locations_abbreviation, "-", local.purpose, "-sql-", local.sequence, "-PE"]) 
  location            = data.azurerm_resource_group.rg[each.key].location
  resource_group_name = (lookup(each.value,"RGname",null) != null && lookup(each.value,"RGname","") != "" && var.RGname!="") ? each.value.RGname : data.azurerm_resource_group.rg[each.key].name
  subnet_id           = data.azurerm_subnet.subnet[each.key].id

  private_service_connection {
    name                           = join("", [local.naming.bu, "-", local.naming.environment, "-", local.env_location.locations_abbreviation, "-", local.purpose, "-sql-", local.sequence, "-PSconnection"]) 
    private_connection_resource_id = azurerm_mssql_server.mssqlserver[each.key].id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  # private_dns_zone_group {
  #   name                 = "example-dns-zone-group"
  #   private_dns_zone_ids = [azurerm_private_dns_zone.example.id]
  # }
}

# resource "azurerm_private_dns_zone" "example" {
#   name                = "privatelink.blob.core.windows.net"
#   resource_group_name = azurerm_resource_group.example.name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "example" {
#   name                  = "example-link"
#   resource_group_name   = azurerm_resource_group.example.name
#   private_dns_zone_name = azurerm_private_dns_zone.example.name
#   virtual_network_id    = azurerm_virtual_network.example.id
# }