// Failover group configuration
provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

locals {
  get_data       = csvdecode(file("../parameters.csv"))
  purpose_parts  = split("/", var.purpose)
  purpose        = length(local.purpose_parts) > 0 ? local.purpose_parts[0] : "default"
  sequence       = length(local.purpose_parts) > 1 ? local.purpose_parts[1] : "01"
  
  naming = {
    bu               = lower(split("-", data.azurerm_subscription.current.display_name)[1])
    environment      = lower(split("-", data.azurerm_subscription.current.display_name)[2])
    locations        = var.location
    secondary_location = var.secondary_location
  }

  env_location = {
    env_abbreviation              = var.environment_map[local.naming.environment]
    locations_abbreviation        = var.location_map[local.naming.locations]
    secondary_location_abbreviation = var.location_map[local.naming.secondary_location]
  }
}

data "azurerm_resource_group" "rg" {
  for_each = { for inst in local.get_data : inst.unique_id => inst }
  name     = join("-", [local.naming.bu, local.naming.environment, local.env_location.locations_abbreviation, var.purpose_rg, "rg"])
}

data "azurerm_mssql_server" "primary_server" {
  name                = join("", [local.naming.bu, "-", local.naming.environment, "-", local.env_location.locations_abbreviation, "-", local.purpose, "-sql-", local.sequence]) 
  resource_group_name = one(values(data.azurerm_resource_group.rg)).name
}

# Get secondary server details
data "azurerm_mssql_server" "secondary_server" {
  name                = join("", [local.naming.bu, "-", local.naming.environment, "-", local.env_location.secondary_location_abbreviation, "-", local.purpose, "-sql-", local.sequence])
  resource_group_name = one(values(data.azurerm_resource_group.rg)).name
}

# Get database details
data "azurerm_mssql_database" "databases" {
  for_each = toset(var.database_names)
  name      = join("", [
    local.naming.bu, "-",
    local.naming.environment, "-",
    local.env_location.locations_abbreviation, "-",
    each.value, "-sqldb-",
    local.sequence
  ])
  server_id = data.azurerm_mssql_server.primary_server.id
}

resource "azurerm_mssql_failover_group" "failover" {
  name      = join("", [
    local.naming.bu, "-",
    local.naming.environment, "-",
    local.env_location.locations_abbreviation, "-",
    local.env_location.secondary_location_abbreviation, "-fog-",
    local.purpose, "-",
    local.sequence
  ])
  server_id = data.azurerm_mssql_server.primary_server.id
  databases = values(data.azurerm_mssql_database.databases)[*].id

  partner_server {
    id = data.azurerm_mssql_server.secondary_server.id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
}

output "failover_group_id" {
  value = azurerm_mssql_failover_group.failover.id 
} 