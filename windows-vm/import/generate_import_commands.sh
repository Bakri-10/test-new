#!/bin/bash
# This script generates Terraform import commands for an existing Windows VM

# Check if required parameters are provided
if [ $# -lt 3 ]; then
  echo "Usage: $0 <vm_resource_id> <rg_resource_id> <nic1_resource_id> [nic2_resource_id] [data_disk_ids_json]"
  echo "Example: $0 /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Compute/virtualMachines/my-vm /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/networkInterfaces/my-nic"
  exit 1
fi

VM_ID=$1
RG_ID=$2
NIC1_ID=$3
NIC2_ID=$4
DATA_DISK_IDS=$5

# Extract VM name and resource group name from resource IDs
VM_NAME=$(basename "$VM_ID")
RG_NAME=$(echo "$RG_ID" | awk -F/ '{print $NF}')

# Create import script file
IMPORT_SCRIPT="terraform_import_commands.sh"

echo "#!/bin/bash" > $IMPORT_SCRIPT
echo "set -e" >> $IMPORT_SCRIPT
echo "" >> $IMPORT_SCRIPT
echo "# Import commands generated on $(date)" >> $IMPORT_SCRIPT
echo "" >> $IMPORT_SCRIPT

# Add resource group import command
echo "echo \"Importing resource group: $RG_NAME\"" >> $IMPORT_SCRIPT
echo "terraform import azurerm_resource_group.import $RG_ID" >> $IMPORT_SCRIPT
echo "" >> $IMPORT_SCRIPT

# Add VM import command
echo "echo \"Importing VM: $VM_NAME\"" >> $IMPORT_SCRIPT
echo "terraform import azurerm_windows_virtual_machine.import $VM_ID" >> $IMPORT_SCRIPT
echo "" >> $IMPORT_SCRIPT

# Add primary NIC import command
echo "echo \"Importing primary NIC\"" >> $IMPORT_SCRIPT
echo "terraform import azurerm_network_interface.import_nic1 $NIC1_ID" >> $IMPORT_SCRIPT
echo "" >> $IMPORT_SCRIPT

# Add secondary NIC import command if provided
if [ -n "$NIC2_ID" ]; then
  echo "echo \"Importing secondary NIC\"" >> $IMPORT_SCRIPT
  echo "terraform import 'azurerm_network_interface.import_nic2[0]' $NIC2_ID" >> $IMPORT_SCRIPT
  echo "" >> $IMPORT_SCRIPT
fi

# Add data disk import commands if provided
if [ -n "$DATA_DISK_IDS" ] && [ "$DATA_DISK_IDS" != "[]" ]; then
  echo "echo \"Importing data disks\"" >> $IMPORT_SCRIPT
  
  # Parse JSON array of data disk IDs
  DISK_COUNT=$(echo "$DATA_DISK_IDS" | jq 'length')
  
  if [ $DISK_COUNT -gt 0 ]; then
    for i in $(seq 0 $(($DISK_COUNT-1))); do
      DISK_ID=$(echo "$DATA_DISK_IDS" | jq -r ".[$i]")
      echo "echo \"Importing data disk $i\"" >> $IMPORT_SCRIPT
      echo "terraform import 'azurerm_managed_disk.import_data_disk[$i]' $DISK_ID" >> $IMPORT_SCRIPT
    done
    echo "" >> $IMPORT_SCRIPT
  fi
fi

echo "echo \"Import completed successfully\"" >> $IMPORT_SCRIPT

# Make the script executable
chmod +x $IMPORT_SCRIPT

echo "Import commands have been generated in $IMPORT_SCRIPT"
echo "Review the file and run it to perform the import" 