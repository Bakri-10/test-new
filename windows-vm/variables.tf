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
variable "valid_priorities" {
  type = list(string)
  description = "Valid options for priority variable"
  default = [
    "Regular",
    "Spot"
  ]
 }
#
variable "request_type" {
  type        = string
  description = "request_type"
  default     = "Create (with New RG)"
 }
variable "location" {
  type        = string
  description = "(Required) The location (region) where the resource is to be deployed. eastus2 and uksouth are the primary locations. centralus and ukwest are for disaster recovery."
 }
variable "vm_size" {
  type          = string
  default       = "Standard_D2s_v3"
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
variable "project_ou" {
  type        = string
  default     = ""
  description = "(Required) The Active Directory Organizational Unit (OU) for you project."
 }
variable "subnetname_wvm" {
  type        = string
  default     = ""
  description = "(Required) The name of the subnet for the VM's network interface."
 }
 variable "subnetname_wvm2" {
  type        = string
  default     = ""
  description = "(Required) The name of the second subnet for the VM's network interface."
 }
variable "disk_size_gb" {
  type        = string
  default     = "32"
  description = "(Optional) The size of all data disks requested."
 }
variable "disk_storage_account_type" {
  type        = string
  default     = "Standard_LRS"
  description = "(Optional) The Type of Storage Account which should back this the Internal OS Disk. Refer to valid_data_storage_account_types."
 }
variable "unique_id" {
  type        = string
  default     = "0"
  description = "(Required) Ensures that each row in the map derived from the CSV File is unique."
 }
#
variable "data_disk_count" {
  type        = string
  default     = "1"
  description = "(Optional) The number of disks to create. This is the CSV File property name. GA UI has an 'ui only' approach."
 }
variable "data_disk_size_gb" {
  type        = string
  default     = ""
  description = "(Optional) The size of all data disks requested."
 }
variable "data_disk_storage_account_type" {
  type        = string
  default     = ""
  description = "(Optional) The Type of Storage Account which should back this the Internal OS Disk. Refer to valid_data_storage_account_types."
 }
variable "enable_automatic_updates" {
  type        = string
  default     = "true"
  description = "(Optional) Specifies if Automatic Updates are Enabled for the Windows Virtual Machine."
 }
variable "eviction_policy" {
  type        = string
  default     = "Delete"
  description = "(Optional) Specifies what should happen when the Virtual Machine is evicted for price reasons when using a Spot instance. Refer to valid_eviction_policies."
 }
variable "image_reference_sku" {
  type        = string
  default       = "2019-Datacenter"
  description = "(Optional) Refer to valid_image_reference_skus for the valid image types."
 }
variable "max_bid_price" {
  type        = string
  default     = "-1"
  description = "(Optional) For 'Spot' VMs, the maximum price you're willing to pay for this Virtual Machine, in US Dollars; which must be greater than the current spot price. If this bid price falls below the current spot price the Virtual Machine will be evicted using the eviction_policy. Defaults to -1, which means that the Virtual Machine should not be evicted for price reasons."
 }
variable "os_disk_caching" {
  type        = string
  default     = "ReadWrite"
  description = "(Optional) os_disk_caching."
 }
variable "os_disk_size_gb" {
  type        = string
  default     = "0"
  description = "(Optional) os_disk_size_gb."
 }
variable "os_disk_storage_account_type" {
  type        = string
  default     = "Standard_LRS"
  description = "(Optional) The Type of Storage Account which should back this the Internal OS Disk. Refer to valid_data_storage_account_types."
 }
variable "priority" {
  type        = string
  default     = "Regular"
  description = "(Optional) Specifies the priority for the virtual machine. Refer to valid_priorities."
 }
variable "timezone" {
  type        = string
  default     = ""
  description = "(Optional) Specifies the Time Zone which should be used by the Virtual Machine. If no value is provided the associated value from the timezone_xref variable is used."
 }
variable "ultra_ssd_enabled" {
  type        = string
  default     = "false"
  description = "(Optional) Should the capacity to enable Data Disks of the UltraSSD_LRS storage account type be supported on this Virtual Machine? "
 }
variable "zone" {
  type        = string
  default     = ""
  description = "(Optional) Specifies the Availability Zone in which this Windows Virtual Machine should be located. "
 }
