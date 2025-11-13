# Terraform Azure GitHub Integration Extension

This extension automatically creates and configures GitHub repositories for integration deployments. It supports two operational modes: full repository setup for new integrations and spoke-outputs auto-update for maintaining synchronization with spoke changes.

## Purpose

This extension is used by the spoke deployment system to:

1. **Create GitHub repositories** for integration workloads
2. **Populate repositories** with Terraform configurations and spoke data
3. **Set up automated deployment workflows** via GitHub Actions
4. **Maintain spoke-integration synchronization** via auto-update functionality
5. **Pass spoke outputs** as variables for integration resources

## Usage

This extension supports two operational modes:

### 1. Full Integration Repository Setup (Default)

Creates a complete integration repository with all necessary files and configurations:

```hcl
module "github_integration" {
  source = "../terraform-azurerm-extension-gh-integration"
  
  repository_name = "pdk-dev-function-integration"
  repository_description = "PDK Development Function App Integration"
  
  # Spoke configuration
  spoke_name = "pdk-dev"
  subscription_id = "12345678-1234-1234-1234-123456789abc"
  spoke_resource_group_name = "rg-pdk-dev-spoke"
  spoke_location = "West Europe"
  
  # Key Vault
  key_vault_id = "/subscriptions/.../resourceGroups/rg-pdk-dev-spoke/providers/Microsoft.KeyVault/vaults/kv-pdk-dev"
  key_vault_name = "kv-pdk-dev"
  
  # Virtual Network
  virtual_network_id = "/subscriptions/.../resourceGroups/rg-pdk-dev-spoke/providers/Microsoft.Network/virtualNetworks/vnet-pdk-dev"
  virtual_network_name = "vnet-pdk-dev"
  
  # All subnet information (user chooses which to use in main.tf)
  subnet_ids = {
    "default"     = "/subscriptions/.../subnets/snet-pdk-dev-default"
    "integration" = "/subscriptions/.../subnets/snet-pdk-dev-integration"
    "backend"     = "/subscriptions/.../subnets/snet-pdk-dev-backend"
  }
  
  subnet_names = {
    "default"     = "snet-pdk-dev-default"
    "integration" = "snet-pdk-dev-integration" 
    "backend"     = "snet-pdk-dev-backend"
  }
  
  # Optional components
  log_analytics_workspace_id = "/subscriptions/.../resourceGroups/rg-pdk-dev-spoke/providers/Microsoft.OperationalInsights/workspaces/log-pdk-dev"
  application_insights_id = "/subscriptions/.../resourceGroups/rg-pdk-dev-spoke/providers/Microsoft.Insights/components/appi-pdk-dev"
}
```

### 2. Automatic Updates on Subsequent Deployments

The extension automatically detects if this is the first deployment (creates all files) or a subsequent deployment (updates only spoke-outputs.tfvars):

- **First deployment**: Creates all repository files including main.tf, variables.tf, etc.
- **Subsequent deployments**: Only updates spoke-outputs.tfvars with latest spoke configuration
- **User's main.tf preserved**: Custom integration configurations remain untouched

## What This Creates

### First Deployment

1. **GitHub Repository** with proper settings and topics
2. **Terraform Files**:
   - `main.tf` - Integration resource configuration template
   - `variables.tf` - Variable definitions
   - `outputs.tf` - Output definitions
   - `spoke-outputs.tfvars` - Complete spoke data with ALL subnet options
   - `versions.tf` - Provider version constraints
   - `providers.tf` - Provider configuration
   - `backend.tf` - Azure backend configuration
3. **GitHub Actions Workflow** for automated deployment
4. **README.md** with usage documentation

### Subsequent Deployments

1. **Updated spoke-outputs.tfvars** with latest spoke configuration and ALL current subnets
2. **Preserved custom configurations** in main.tf and other user-modified files
3. **User choice flexibility** - all subnets available, user chooses which to use

## Subnet Selection Approach

The extension passes **ALL** subnets from the spoke deployment in the `spoke-outputs.tfvars` file:

```hcl
subnet_ids = {
  "default"     = "/subscriptions/.../subnets/snet-pdk-dev-default"
  "integration" = "/subscriptions/.../subnets/snet-pdk-dev-integration"
  "backend"     = "/subscriptions/.../subnets/snet-pdk-dev-backend"
}
```

Users then choose which subnet to use in their `main.tf` configuration:

```hcl
module "function_app" {
  source = "..."
  
  # Choose the integration subnet for VNet integration
  subnet_id = var.subnet_ids["integration"]
  
  # Or choose the backend subnet for private endpoints  
  private_endpoint_subnet_id = var.subnet_ids["backend"]
}

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `repository_name` | Name of the integration repository | `string` | n/a | yes |
| `repository_description` | Description of the integration repository | `string` | `""` | no |
| `spoke_name` | Name of the spoke deployment | `string` | n/a | yes |
| `subscription_id` | Azure subscription ID | `string` | n/a | yes |
| `spoke_resource_group_name` | Spoke resource group name | `string` | n/a | yes |
| `spoke_location` | Spoke location | `string` | n/a | yes |
| `key_vault_id` | Key Vault resource ID | `string` | n/a | yes |
| `key_vault_name` | Key Vault name | `string` | n/a | yes |
| `virtual_network_id` | Virtual network resource ID | `string` | n/a | yes |
| `virtual_network_name` | Virtual network name | `string` | n/a | yes |
| `subnet_ids` | Map of all subnet IDs from spoke deployment | `map(string)` | `{}` | no |
| `subnet_names` | Map of all subnet names from spoke deployment | `map(string)` | `{}` | no |
| `log_analytics_workspace_id` | Log Analytics workspace resource ID | `string` | `""` | no |
| `application_insights_id` | Application Insights resource ID | `string` | `""` | no |
| `project_name` | Name of integration project (deprecated - use repository_name) | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| `integration_repository_name` | Name of the integration repository |
| `integration_repository_url` | URL of the integration repository |
| `integration_repository_clone_url` | Clone URL of the integration repository |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| github | ~> 6.0 |

## Templates

The extension uses template files to generate repository content:

- `main.tfvars.tpl` - Complete spoke-outputs template for full setup
- `spoke-outputs-update.tfvars.tpl` - Minimal template for auto-update mode
- `main.tf.tpl`, `variables.tf.tpl`, etc. - Terraform configuration templates

## Related Documentation

- [Spoke Deployment System](../spokedeployment-tf/Docs/HowToUseSpokeDeployment.md)
- [GitHub Repository Extension](../terraform-azurerm-extension-gh-repo/README.md)
- [Integration Resources Module](../terraform-azurerm-integration-resources/README.md)