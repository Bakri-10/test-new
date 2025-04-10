// Variables for the import process
variable "vm_name" {
  type        = string
  description = "Name of the VM being imported"
}

variable "rg_name" {
  type        = string
  description = "Name of the resource group containing the VM"
}

variable "location" {
  type        = string
  description = "Azure region of the VM"
}

variable "subnet1_id" {
  type        = string
  description = "ID of the primary subnet"
  default     = ""
}

variable "subnet2_id" {
  type        = string
  description = "ID of the secondary subnet"
  default     = ""
}

variable "include_extensions" {
  type        = bool
  description = "Whether to include VM extensions in the import"
  default     = false
}

variable "extensions_json" {
  type        = string
  description = "JSON object containing VM extension details"
  default     = "{\"extensions\":{}}"
} 