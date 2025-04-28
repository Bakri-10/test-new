╷
│ Error: Invalid combination of arguments
│ 
│   with azurerm_windows_virtual_machine.main,
│   on main.tf line 292, in resource "azurerm_windows_virtual_machine" "main":
│  292: resource "azurerm_windows_virtual_machine" "main" {
│ 
│ "source_image_id": one of `source_image_id,source_image_reference` must be
│ specified
╵
╷
│ Error: Invalid combination of arguments
│ 
│   with azurerm_windows_virtual_machine.main,
│   on main.tf line 292, in resource "azurerm_windows_virtual_machine" "main":
│  292: resource "azurerm_windows_virtual_machine" "main" {
│ 
│ "source_image_reference": one of `source_image_id,source_image_reference`
│ must be specified
╵
╷
│ Error: "name" must not be empty
│ 
│   with azurerm_windows_virtual_machine.main,
│   on main.tf line 295, in resource "azurerm_windows_virtual_machine" "main":
│  295:   name                = ""
│ 
╵
╷
│ Error: expected "location" to not be an empty string, got 
│ 
│   with azurerm_windows_virtual_machine.main,
│   on main.tf line 296, in resource "azurerm_windows_virtual_machine" "main":
│  296:   location            = ""
│ 
╵
╷
│ Error: "resource_group_name" cannot be blank
│ 
│   with azurerm_windows_virtual_machine.main,
│   on main.tf line 297, in resource "azurerm_windows_virtual_machine" "main":
│  297:   resource_group_name = ""
│ 
╵
╷
│ Error: expected "size" to not be an empty string, got 
│ 
│   with azurerm_windows_virtual_machine.main,
│   on main.tf line 298, in resource "azurerm_windows_virtual_machine" "main":
│  298:   size                = ""
│ 
╵
╷
│ Error: "admin_username" must not be empty
│ 
│   with azurerm_windows_virtual_machine.main,
│   on main.tf line 299, in resource "azurerm_windows_virtual_machine" "main":
│  299:   admin_username      = ""
│ 
╵
╷
│ Error: "admin_password" must not be empty
│ 
│   with azurerm_windows_virtual_machine.main,
│   on main.tf line 300, in resource "azurerm_windows_virtual_machine" "main":
│  300:   admin_password      = ""
│ 
╵
╷
│ Error: Not enough list items
│ 
│   with azurerm_windows_virtual_machine.main,
│   on main.tf line 301, in resource "azurerm_windows_virtual_machine" "main":
│  301:   network_interface_ids = []
│ 
│ Attribute network_interface_ids requires 1 item minimum, but config has
│ only 0 declared.
╵
╷
│ Error: expected os_disk.0.caching to be one of ["None" "ReadOnly" "ReadWrite"], got 
│ 
│   with azurerm_windows_virtual_machine.main,
│   on main.tf line 303, in resource "azurerm_windows_virtual_machine" "main":
│  303:     caching           = ""
│ 
╵
╷
│ Error: expected os_disk.0.storage_account_type to be one of ["Premium_LRS" "Standard_LRS" "StandardSSD_LRS" "StandardSSD_ZRS" "Premium_ZRS"], got 
│ 
│   with azurerm_windows_virtual_machine.main,
│   on main.tf line 304, in resource "azurerm_windows_virtual_machine" "main":
│  304:     storage_account_type = ""
│ 
╵
╷
│ Error: expected "location" to not be an empty string, got 
│ 
│   with azurerm_network_interface.nic1,
│   on main.tf line 313, in resource "azurerm_network_interface" "nic1":
│  313:   location            = ""
│ 
╵
╷
│ Error: "resource_group_name" cannot be blank
│ 
│   with azurerm_network_interface.nic1,
│   on main.tf line 314, in resource "azurerm_network_interface" "nic1":
│  314:   resource_group_name = ""
│ 
╵
╷
│ Error: expected "ip_configuration.0.name" to not be an empty string, got 
│ 
│   with azurerm_network_interface.nic1,
│   on main.tf line 316, in resource "azurerm_network_interface" "nic1":
│  316:     name                          = ""
│ 
╵
╷
│ Error: parsing "": cannot parse an empty string
│ 
│   with azurerm_network_interface.nic1,
│   on main.tf line 317, in resource "azurerm_network_interface" "nic1":
│  317:     subnet_id                     = ""
│ 
╵
╷
│ Error: expected ip_configuration.0.private_ip_address_allocation to be one of ["Dynamic" "Static"], got 
│ 
│   with azurerm_network_interface.nic1,
│   on main.tf line 318, in resource "azurerm_network_interface" "nic1":
│  318:     private_ip_address_allocation = ""
│ 
╵
╷
│ Error: expected "location" to not be an empty string, got 
│ 
│   with azurerm_network_interface.nic2,
│   on main.tf line 326, in resource "azurerm_network_interface" "nic2":
│  326:   location            = ""
│ 
╵
╷
│ Error: "resource_group_name" cannot be blank
│ 
│   with azurerm_network_interface.nic2,
│   on main.tf line 327, in resource "azurerm_network_interface" "nic2":
│  327:   resource_group_name = ""
│ 
╵
╷
│ Error: expected "ip_configuration.0.name" to not be an empty string, got 
│ 
│   with azurerm_network_interface.nic2,
│   on main.tf line 329, in resource "azurerm_network_interface" "nic2":
│  329:     name                          = ""
│ 
╵
╷
│ Error: parsing "": cannot parse an empty string
│ 
│   with azurerm_network_interface.nic2,
│   on main.tf line 330, in resource "azurerm_network_interface" "nic2":
│  330:     subnet_id                     = ""
│ 
╵
╷
│ Error: expected ip_configuration.0.private_ip_address_allocation to be one of ["Dynamic" "Static"], got 
│ 
│   with azurerm_network_interface.nic2,
│   on main.tf line 331, in resource "azurerm_network_interface" "nic2":
│  331:     private_ip_address_allocation = ""
│ 
╵
╷
│ Error: expected "name" to not be an empty string, got 
│ 
│   with azurerm_virtual_machine_extension.custom_extensions,
│   on main.tf line 339, in resource "azurerm_virtual_machine_extension" "custom_extensions":
│  339:   name                 = ""
│ 
╵
╷
│ Error: parsing "": cannot parse an empty string
│ 
│   with azurerm_virtual_machine_extension.custom_extensions,
│   on main.tf line 340, in resource "azurerm_virtual_machine_extension" "custom_extensions":
│  340:   virtual_machine_id   = ""
│ 
╵
╷
│ Error: expected "name" to not be an empty string, got 
│ 
│   with azurerm_virtual_machine_extension.domain_join,
│   on main.tf line 349, in resource "azurerm_virtual_machine_extension" "domain_join":
│  349:   name                 = ""
│ 
╵
╷
│ Error: parsing "": cannot parse an empty string
│ 
│   with azurerm_virtual_machine_extension.domain_join,
│   on main.tf line 350, in resource "azurerm_virtual_machine_extension" "domain_join":
│  350:   virtual_machine_id   = ""
│ 
