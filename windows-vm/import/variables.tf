variable "environment_abbr_xref" {
  type        = map(any)
  description = "This variable is used internally to cross-reference a provided environment to the appropriate abbreviation."
  default = {
    "dev"   = "dv"
    "fof"   = "ff"
    "prd"   = "pd"
    "prod"  = "pd"
    "qa"    = "qa"
    "uat"   = "ut"
  }
 }
variable "location_xref" {
  type        = map(any)
  description = "This variable is used internally to cross-reference a provided location name to the appropriate abbreviation."
  default = {
    "eastus2"   = "eus2"
    "centralus" = "cus"
    "uksouth"   = "uks"
    "ukwest"    = "ukw"
  }
 }

# VM Import specific variables
variable "location" {
  type        = string
  description = "(Required) The location (region) where the VM is deployed."
}

variable "vm_name" {
  type        = string
  description = "(Required) The name of the VM to import."
  validation {
    condition     = length(var.vm_name) > 0
    error_message = "VM name cannot be empty."
  }
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group containing the VM."
  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "Resource group name cannot be empty."
  }
}

variable "nic_count" {
  type        = string
  description = "(Required) The number of network interfaces attached to the VM."
  default     = "1"
  validation {
    condition     = can(tonumber(var.nic_count)) && tonumber(var.nic_count) > 0
    error_message = "NIC count must be a numeric string with value of at least 1."
  }
}

variable "nic_names" {
  type        = string
  description = "(Optional) Comma-separated list of custom NIC names. If not provided, names will be generated based on VM name."
}

variable "os_disk_name" {
  type        = string
  description = "(Optional) Custom name for the OS disk. If not provided, will be generated based on VM name."
  default     = null
}

variable "data_disk_count" {
  type        = string
  description = "(Optional) The number of data disks attached to the VM."
  default     = "0"
  validation {
    condition     = can(tonumber(var.data_disk_count)) && tonumber(var.data_disk_count) >= 0
    error_message = "Data disk count must be a numeric string with value of 0 or greater."
  }
}

variable "data_disk_names" {
  type        = string
  description = "(Optional) Comma-separated list of custom data disk names. If not provided, names will be generated based on VM name."
}

variable "vm_size" {
  type        = string
  description = "(Required) The size of the VM to import (e.g. Standard_D2s_v3, Standard_F4s_v2)"
  default     = "Standard_D2s_v3"
} 