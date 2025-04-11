╷
│ Error: Invalid value for variable
│ 
│   on variables.tf line 106:
│  106: variable "request_type" {
│     ├────────────────
│     │ var.request_type is "Backup VM"
│ 
│ Invalid request type. Must be one of: Create (with New RG), Create (with
│ Existing RG), Update (Data Disk), Update (OS Disk), Update VM SKU, Remove
│ (Destroy VM), Start VM, Stop VM, Restart VM
│ 
│ This was checked by the validation rule at variables.tf:109,3-13.
╵
