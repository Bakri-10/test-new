╷
│ Error: creating Vault (Subscription: "***"
│ Resource Group Name: "6425-dev-eus2-sgs-rg"
│ Vault Name: "DefaultBackupVault"): performing CreateOrUpdate: unexpected status 403 (403 Forbidden) with error: RequestDisallowedByPolicy: Resource 'DefaultBackupVault' was disallowed by policy. Policy identifiers: '[{"policyAssignment":{"name":"Restricts the naming of specific resources based on the naming standard - Assignment","id":"/providers/Microsoft.Management/managementGroups/Global/providers/Microsoft.Authorization/policyAssignments/SetNamingConvention"},"policyDefinition":{"name":"Restricts the naming of specific resources based on the naming standard","id":"/providers/Microsoft.Management/managementGroups/Global/providers/Microsoft.Authorization/policyDefinitions/SetNamingConvention","version":"1.0.0"},"policySetDefinition":{"name":"Set Naming Convention Initiative Definition","id":"/providers/Microsoft.Management/managementGroups/Global/providers/Microsoft.Authorization/policySetDefinitions/SetNamingConventionInitiative","version":"1.0.0"}}]'.
│ 
│   with azurerm_recovery_services_vault.backup[0],
│   on main.tf line 152, in resource "azurerm_recovery_services_vault" "backup":
│  152: resource "azurerm_recovery_services_vault" "backup" {
│ 
╵
