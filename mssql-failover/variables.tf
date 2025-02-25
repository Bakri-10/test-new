variable "database_names" {
  type        = list(string)
  description = "Comma-separated list of database names to include in failover group"
}

variable "location" {
  type        = string
  description = "Primary location for resources"
}

variable "secondary_location" {
  type        = string
  description = "Secondary location for failover"
}

variable "purpose" {
  type        = string
  description = "Purpose of the failover group"
}

variable "purpose_rg" {
  type        = string
  description = "Purpose for resource group naming"
}

variable "environment_map" {
  type = map(string)
  default = {
    "dev"  = "dev"
    "uat"  = "uat"
    "fof"  = "fof"
    "prod" = "prod"
    "qa"   = "qa"
  }
}

variable "location_map" {
  type = map(string)
  default = {
    "eastus2"   = "eus2"
    "centralus" = "cus"
    "uksouth"   = "uks"
    "ukwest"    = "ukw"
    "us"        = "eus2"
  }
}

variable "environment" {
  type        = string
  description = "Environment (dev, qa, uat, prod, fof)"
}

variable "database_license_type" {
  type = string
  default = "LicenseIncluded"
  description = "Type of license for the database"
} 

variable "primary_server"{
  type = string
  description = "Name of primary server"
}

variable "secondary_server"{
  type = string
  description = "Name of secondary server"
}