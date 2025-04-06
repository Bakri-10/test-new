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
variable "environment_gad_xref" {
  type        = map(any)
  description = "This variable is used internally to cross-reference a provided environment to the appropriate abbreviation."
  default = {
    "dev"   = "dv"
    "fof"   = "ff"
    "prd"   = "pr"
    "prod"  = "pr"
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
variable "location_gad_xref" {
  type        = map(any)
  description = "This variable is used internally to cross-reference a provided location name to the abbreviation used by Global Active Directory."
  default = {
    "eastus2"   = "USE"
    "centralus" = "CUS"
    "uksouth"   = "UKS"
    "ukwest"    = "UKW"
  }
 }
variable "timezone_xref" {
  type        = map(any)
  description = "This variable is used internally to associate the location to the appropriate timezon."
  default = {
    "eastus2"   = "US Eastern Standard Time"
    "centralus" = "Central Standard Time"
    "uksouth"   = "GMT Standard Time"
    "ukwest"    = "GMT Standard Time"
  }
 }
#
variable "valid_data_storage_account_types" {
  type = list(string)
  description = "Valid options for data disk storage types."
  default = [
    "Premium_LRS",
    "Premium_ZRS",
    # "PremiumV2_LRS" - Removed to allow Encryption at Host (EaH)
    "Standard_LRS",
    "StandardSSD_LRS",
    "StandardSSD_ZRS"
    # "UltraSSD_LRS" - Removed to allow EaH
  ]
 }
variable "valid_eviction_policies" {
  type = list(string)
  description = "Valid options for eviction_type variable"
  default = [
    "Deallocate",
    "Delete"
  ]
 }
variable "valid_image_reference_skus" {
  type = list(string)
  description = "Valid options for image_reference_sku variable"
  default = [
    "2016-Datacenter",
    "2019-Datacenter"
  ]
 }
variable "valid_os_disk_caching_types" {
  type = list(string)
  description = "Valid options for os disk storage types."
  default = [
    "None",
    "ReadOnly",
    "ReadWrite"
  ]
 }
variable "valid_os_storage_account_types" {
  type = list(string)
  description = "Valid options for os disk storage types."
  default = [
    "Premium_LRS",
    "Premium_ZRS",
    "Standard_LRS",
    "StandardSSD_LRS",
    "StandardSSD_ZRS"
  ]
 }
#
variable "request_type" {
  type        = string
  description = "Request type for VM operations"
  validation {
    condition     = contains([
      "Create (with New RG)",
      "Create (with Existing RG)",
      "Update (Data Disk)",
      "Update (OS Disk)",
      "Update VM SKU",
      "Remove (Destroy VM)",
      "Start VM",
      "Stop VM",
      "Restart VM",
      "Backup VM",
      "Restore VM"
    ], var.request_type)
    error_message = "Invalid request type. Must be one of: Create (with New RG), Create (with Existing RG), Update (Data Disk), Update (OS Disk), Update VM SKU, Remove (Destroy VM), Start VM, Stop VM, Restart VM, Backup VM, Restore VM"
  }
}
variable "location" {
  type        = string
  description = "(Required) The location (region) where the resource is to be deployed. eastus2 and uksouth are the primary locations. centralus and ukwest are for disaster recovery."
 }
variable "vm_size" {
  type          = string
  default       = ""
  description   = "(Required) Specifies the size for the VMs."
 }
variable "purpose" {
  type        = string
  default     = "default"
  description = "(Required) The VM Role and Sequence for naming use or, submit the desired resource name (one that contains a dash)."
  validation {
    condition     = strcontains(var.purpose, "-") ? length(var.purpose) <= 30 : length(var.purpose) <= 10
    error_message = "(Required) Purpose [VM Role.Sequence] segment cannot exceed 10 characters. Name cannot exceed 80."
  }
 }
variable "purpose_rg" {
  type        = string
  default     = "default"
  description = "(Required) The purpose segment of the Resource Group name. Should not exceed 5 characters."
  validation {
    condition     = strcontains(var.purpose_rg, "-") ? length(var.purpose_rg) <= 80 : length(var.purpose_rg) <= 5
    error_message = "(Required) Purpose segment cannot exceed 5 characters. Name cannot exceed 80."
  }  
 }
# variable "project_ou" {
# variable "subnetname_wvm" {
variable "disk_size_gb" {
  type        = string
  default     = "same"
  description = "disk_size_gb"
 }
variable "disk_storage_account_type" {
  type        = string
  default     = "Standard_LRS"
  description = "disk_storage_account_type"
 }
#