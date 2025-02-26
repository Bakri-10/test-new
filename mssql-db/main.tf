provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    # Backend configuration will be provided via CLI arguments
  }
}

data "azurerm_subscription" "current" {}

locals {
  get_data = csvdecode(file("../parameters.csv"))
  // define data for naming standards 
  purpose_parts = split("/", var.purpose)
  purpose = length(local.purpose_parts) > 0 ? local.purpose_parts[0] : "default"
  sequence = length(local.purpose_parts) > 1 ? local.purpose_parts[1] : "01"
  
  naming = {
    bu = lower(split("-", data.azurerm_subscription.current.display_name)[1])
    environment = lower(split("-", data.azurerm_subscription.current.display_name)[2])
    locations = var.location
  }

  env_location = {
    env_abbreviation = var.environment_map[local.naming.environment]
    locations_abbreviation = var.location_map[local.naming.locations]
  }
}
# data source to get the resource group
data "azurerm_resource_group" "rg" {
  for_each = { for inst in local.get_data : inst.unique_id => inst }
  name     = join("-", [local.naming.bu, local.naming.environment, local.env_location.locations_abbreviation, var.purpose_rg, "rg"])
}

output "resource_group_name" {
  value = data.azurerm_resource_group.rg
}

# data source to reference the SQL server
data "azurerm_mssql_server" "sql_server" {
  name                = var.primary_server
  resource_group_name = one(values(data.azurerm_resource_group.rg)).name
}

resource "azurerm_mssql_database" "sqldb" {
  for_each = { for idx, purpose in var.db_purpose : "${idx}" => purpose }
  
  name           = join("", [local.naming.bu, "-", local.naming.environment, "-", local.env_location.locations_abbreviation, "-", each.value, "-sqldb-", local.sequence])
  server_id      = data.azurerm_mssql_server.sql_server.id 
  collation      = var.dbcollation
  license_type   = "LicenseIncluded"
  sku_name       = var.skuname
  zone_redundant = var.zoneredundancy
}

output "database_ids" {
  value = [for db in azurerm_mssql_database.sqldb : db.id]
}
