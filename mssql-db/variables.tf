variable "db_purpose" {
  type        = list(string)
  description = "List of database purposes"
}

variable "dbcollation" {
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
  description = "Database collation"
}

variable "skuname" {
  type        = string
  description = "SKU name for the database"
}

variable "zoneredundancy" {
  type        = bool
  default     = false
  description = "Enable zone redundancy"
}

variable "location" {
  type        = string
  description = "Primary location for resources"
}

variable "purpose" {
  type        = string
  description = "Purpose of the database"
}

variable "environment_map" {
  type = map(string)
  default = {
    "dev"  = "dev"
    "uat" = "uat"
    "fof" = "fof"
    "prod" = "prod"
    "qa" = "qa"
  }
}

variable "location_map" {
  type = map(string)
  default = {
    "eastus2"  = "eus2"
    "centralus" = "cus"
    "uksouth" = "uks"
    "ukwest" = "ukw"
    "us" = "eus2"
  }
}

variable "purpose_rg" {
  type        = string
  description = "Purpose for resource group naming"
} 
variable "primary_server" {
  type        = string
  description = "Name of Server to deploy database to"
}