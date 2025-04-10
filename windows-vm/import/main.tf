terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.101.0"
      configuration_aliases = [ 
          azurerm.adt
       ]
     }
    azapi = {
      source = "Azure/azapi"
      version = "1.13.1"
     }
  }
  required_version = ">=1.1.0"
  backend "azurerm" {}
} 

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias                               = "adt"
  features {
    virtual_machine {
      delete_os_disk_on_deletion      = true
      graceful_shutdown               = false
    }
  }
}

provider "azapi" {}

// Resources to import
resource "azurerm_resource_group" "import" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_network_interface" "import_nic1" {
  name                = "${var.vm_name}-nic-01"
  location            = azurerm_resource_group.import.location
  resource_group_name = azurerm_resource_group.import.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet1_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "import_nic2" {
  count               = var.subnet2_id != "" ? 1 : 0
  name                = "${var.vm_name}-nic-02"
  location            = azurerm_resource_group.import.location
  resource_group_name = azurerm_resource_group.import.name

  ip_configuration {
    name                          = "ipconfig2"
    subnet_id                     = var.subnet2_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "import_data_disk" {
  count                = 0  # Will be determined during import
  name                 = "${var.vm_name}-data-disk-${count.index}"
  location             = azurerm_resource_group.import.location
  resource_group_name  = azurerm_resource_group.import.name
  storage_account_type = "Standard_LRS"  # Will be updated during import
  create_option        = "Empty"
  disk_size_gb         = 32  # Will be updated during import
}

resource "azurerm_windows_virtual_machine" "import" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.import.name
  location            = azurerm_resource_group.import.location
  size                = "Standard_D2s_v3"  # Will be updated during import
  admin_username      = "vmadmin"  # Will be updated during import
  admin_password      = "TemporaryPassword!123"  # Will be updated during import

  network_interface_ids = var.subnet2_id != "" ? [
    azurerm_network_interface.import_nic1.id,
    azurerm_network_interface.import_nic2[0].id
  ] : [
    azurerm_network_interface.import_nic1.id
  ]

  os_disk {
    caching              = "ReadWrite"  # Will be updated during import
    storage_account_type = "Standard_LRS"  # Will be updated during import
  }

  # Source image reference will be populated during import
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  # Additional configurations will be populated during import
  lifecycle {
    ignore_changes = [
      admin_password,
      source_image_reference,
      os_disk,
      additional_capabilities,
      network_interface_ids
    ]
  }
}

// Add VM extensions if requested
resource "azurerm_virtual_machine_extension" "import_extension" {
  for_each                   = var.include_extensions ? jsondecode(var.extensions_json).extensions : {}
  
  name                       = each.key
  virtual_machine_id         = azurerm_windows_virtual_machine.import.id
  publisher                  = each.value.publisher
  type                       = each.value.type
  type_handler_version       = each.value.typeHandlerVersion
  auto_upgrade_minor_version = true

  lifecycle {
    ignore_changes = [
      settings,
      protected_settings,
      tags,
      auto_upgrade_minor_version
    ]
  }
} 