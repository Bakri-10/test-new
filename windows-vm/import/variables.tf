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
  type        = number
  description = "(Required) The number of network interfaces attached to the VM."
  default     = 1
  validation {
    condition     = var.nic_count > 0
    error_message = "NIC count must be at least 1."
  }
}

variable "data_disk_count" {
  type        = number
  description = "(Optional) The number of data disks attached to the VM."
  default     = 0
  validation {
    condition     = var.data_disk_count >= 0
    error_message = "Data disk count must be 0 or greater."
  }
} 