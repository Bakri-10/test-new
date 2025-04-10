#!/bin/bash
# Post-import migration script
# This script helps transition from the import configuration to standard Terraform management

set -e

# Check if environment variables are set
if [ -z "$VM_NAME" ] || [ -z "$RG_NAME" ] || [ -z "$ENVIRONMENT" ]; then
  echo "Required environment variables not set."
  echo "Usage: VM_NAME=myvm RG_NAME=myrg ENVIRONMENT=dev ./post_import_migration.sh"
  exit 1
fi

# Define paths
IMPORT_DIR="$(pwd)"
STANDARD_DIR="../"
MIGRATION_DIR="migration"

echo "Starting post-import migration process for VM: $VM_NAME"

# Create migration directory
mkdir -p "$MIGRATION_DIR"

# Step 1: Extract VM details from the imported state
echo "Extracting VM details from imported state..."

# Get VM size
VM_SIZE=$(terraform state show azurerm_windows_virtual_machine.import | grep "size " | awk -F'= ' '{print $2}' | tr -d '"')
if [ -z "$VM_SIZE" ]; then
  VM_SIZE=$(terraform output -json | jq -r '.import_details.value.vm_size // "Standard_D2s_v3"')
fi

# Get VM location
LOCATION=$(terraform output -json | jq -r '.import_details.value.location // "eastus2"')

# Get network information
VNET_NAME=$(terraform output -json | jq -r '.import_details.value.vnet_name // ""')

# Step 2: Generate terraform.tfvars file with imported values
echo "Generating terraform.tfvars file..."
cat > "$MIGRATION_DIR/terraform.tfvars" <<EOF
# Generated tfvars file based on imported resources
# VM: $VM_NAME
# Resource Group: $RG_NAME
# Environment: $ENVIRONMENT
# Generated: $(date)

request_type = "Create (with Existing RG)"
environment = "$ENVIRONMENT"
location = "$LOCATION"
vm_size = "$VM_SIZE"
purpose = "$VM_NAME"
purpose_rg = "$RG_NAME"
project_ou = "Imported-VMs"
EOF

echo "terraform.tfvars file generated in $MIGRATION_DIR/terraform.tfvars"

# Step 3: Generate main.tf with references to imported resources
echo "Generating main.tf with references to imported resources..."

cat > "$MIGRATION_DIR/main.tf" <<EOF
# Migration configuration for imported VM resources
# This file connects the standard Terraform modules to imported resources

# Import reference
data "terraform_remote_state" "import" {
  backend = "azurerm"
  config = {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstate"
    container_name       = "terraform-state"
    key                  = "$ENVIRONMENT-$VM_NAME-import-terraform.tfstate"
  }
}

# Load variables from terraform.tfvars
variable "request_type" {}
variable "environment" {}
variable "location" {}
variable "vm_size" {}
variable "purpose" {}
variable "purpose_rg" {}
variable "project_ou" {}

# Connect to imported VM state
locals {
  vm_id = data.terraform_remote_state.import.outputs.import_details.vm_id
  rg_id = data.terraform_remote_state.import.outputs.import_details.rg_id
  nic1_id = data.terraform_remote_state.import.outputs.import_details.nic1_id
  nic2_id = data.terraform_remote_state.import.outputs.import_details.nic2_id
}

# Output for verification
output "migration_details" {
  value = {
    environment = var.environment
    vm_name = var.purpose
    resource_group = var.purpose_rg
    vm_id = local.vm_id
    vm_size = var.vm_size
  }
}
EOF

echo "main.tf file generated in $MIGRATION_DIR/main.tf"

# Step 4: Copy versions.tf
echo "Copying versions.tf..."
cp "versions.tf" "$MIGRATION_DIR/"

# Step 5: Generate documentation
echo "Generating migration documentation..."
cat > "$MIGRATION_DIR/migration_instructions.md" <<EOF
# VM Import Migration Instructions
## VM Details
- Name: $VM_NAME
- Resource Group: $RG_NAME
- Environment: $ENVIRONMENT
- VM Size: $VM_SIZE
- Location: $LOCATION
- Import Date: $(date)

## Generated Files
- terraform.tfvars: Contains variables extracted from imported VM
- main.tf: References imported VM state
- versions.tf: Provider configurations

## Migration Steps
1. Change to the migration directory:
   \`\`\`bash
   cd $MIGRATION_DIR
   \`\`\`

2. Initialize Terraform:
   \`\`\`bash
   terraform init -backend-config="resource_group_name=terraform-state-rg" \
                 -backend-config="storage_account_name=terraformstate" \
                 -backend-config="container_name=terraform-state" \
                 -backend-config="key=$ENVIRONMENT-$VM_NAME-migration-terraform.tfstate"
   \`\`\`

3. Run a plan to verify the configuration:
   \`\`\`bash
   terraform plan
   \`\`\`

4. Apply the configuration to create the migration state:
   \`\`\`bash
   terraform apply
   \`\`\`

## Next Steps After Successful Migration
1. Use standard Terraform workflows for future changes
2. If needed, update the VM configuration using "Maintain Windows VM" workflows
3. For security, rotate VM credentials

## Troubleshooting
If you encounter issues during migration:
1. Check if all required variables are set correctly
2. Verify the VM and associated resources still exist in Azure
3. If state issues occur, you may need to use \`terraform state\` commands to fix them
4. For complete control, consider moving resources in the state file: \`terraform state mv\`
EOF

echo "Migration documentation generated in $MIGRATION_DIR/migration_instructions.md"

echo "Migration preparation completed successfully."
echo "Next steps:"
echo "1. Review the generated files in the $MIGRATION_DIR directory"
echo "2. Follow the instructions in $MIGRATION_DIR/migration_instructions.md" 