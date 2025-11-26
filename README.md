# Terraform Azure GitHub Integration Extension

This extension automatically creates and configures GitHub repositories for integration deployments. It supports two operational modes: full repository setup for new integrations and spoke-outputs auto-update for maintaining synchronization with spoke changes.

## Quick Setup

1. **Use this extension** to create an integration repository
2. **Configure GitHub Actions** following the [GitHub Actions Setup Guide](GITHUB_ACTIONS_SETUP.md)
3. **Deploy your integration** using the generated Terraform configuration

## Purpose

This extension is used by the spoke deployment system to:
1. **Configure existing GitHub repositories** for integration workloads (repositories are created by a separate extension)
2. **Populate repositories** with Terraform configurations and spoke data
3. **Set up automated deployment workflows** via GitHub Actions
4. **Maintain spoke-integration synchronization** by automatically updating `spoke-outputs.tfvars` with the latest spoke configuration on subsequent deployments
5. **Pass spoke outputs** as variables for integration resources

## Usage

This extension supports two operational modes:

### 1. Full Integration Repository Setup (Default)

Creates a complete integration repository with all necessary files and configurations:

```hcl
module "github_integration" {
  source = "../terraform-azurerm-extension-gh-integration"

  repository_name        = var.repository_name
  repository_description = var.repository_description

  spoke_config = {
    spoke_name                 = var.spoke_config.spoke_name
    subscription_id            = var.spoke_config.subscription_id
    spoke_resource_group_name  = var.spoke_config.spoke_resource_group_name
    spoke_location             = var.spoke_config.spoke_location
    key_vault_id               = var.spoke_config.key_vault_id
    key_vault_name             = var.spoke_config.key_vault_name
    virtual_network_id         = var.spoke_config.virtual_network_id
    virtual_network_name       = var.spoke_config.virtual_network_name
    subnet_ids                 = var.spoke_config.subnet_ids
    subnet_names               = var.spoke_config.subnet_names
    log_analytics_workspace_id = var.spoke_config.log_analytics_workspace_id
    application_insights_id    = var.spoke_config.application_insights_id
  }
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
  "default"     = "/subscriptions/.../subnets/snet-spoke-dev-default"
  "integration" = "/subscriptions/.../subnets/snet-spoke-dev-integration"
  "backend"     = "/subscriptions/.../subnets/snet-spoke-dev-backend"
}
```

Users then choose which subnet to use in their `main.tf` configuration:

```hcl
module "function_app" {
  source = "..."

  # Choose the integration subnet for VNet integration
  subnet_id = var.spoke_config.subnet_ids["integration"]

  # Or choose the backend subnet for private endpoints  
  private_endpoint_subnet_id = var.spoke_config.subnet_ids["backend"]
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `repository_name` | Name of the integration repository | `string` | n/a | yes |
| `repository_description` | Description of the integration repository | `string` | `""` | no |
| `spoke_config` | Consolidated spoke configuration object from spoke-outputs.tfvars. See below for fields. | `object` | n/a | yes |

### `spoke_config` object fields

| Field | Type | Description |
|-------|------|-------------|
| name | string | Spoke name |
| subscription_id | string | Azure subscription ID |
| resource_group_name | string | Spoke resource group name |
| location | string | Spoke location |
| tenant_id | string | Azure tenant ID |
| environment | string | Environment name |
| key_vault_id | string | Key Vault resource ID |
| key_vault_name | string | Key Vault name |
| storage_account_id | string | Storage account resource ID |
| storage_account_name | string | Storage account name |
| virtual_network_id | string | Virtual network resource ID |
| virtual_network_name | string | Virtual network name |
| tags | map(string) | Optional tags |
| subnet_ids | map(string) | Map of all subnet IDs |
| subnet_names | map(string) | Map of all subnet names |
| log_analytics_workspace_id | string | Log Analytics workspace resource ID |
| application_insights_id | string | Application Insights resource ID |

## Outputs



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

## GitHub Actions Configuration

After the repository is created, all required variables and secrets are automatically configured, and connection to the spoke is established. The user only needs to run the GitHub Action to deploy their integration resources (defined in `main.tf`) to the spoke.

**Deployment steps:**
1. **Review the setup guide**: [GitHub Actions Setup](GITHUB_ACTIONS_SETUP.md) (optional, for advanced configuration)
2. **Define your integration resources** in `main.tf` within the generated repository
3. **Run the GitHub Action** (push changes to the repository or manually trigger the workflow)

The generated repository includes a complete GitHub Actions workflow (`terraform.yml`) that automatically:
- Validates Terraform configuration
- Plans infrastructure changes
- Applies changes to the spoke
- Provides detailed debugging output for troubleshooting

## Troubleshooting

### Common Issues

1. **DNS lookup failures for storage accounts**: Check the `TF_STATE_STORAGE_ACCOUNT` variable value
2. **Authentication errors**: Verify Azure credentials in repository secrets
3. **Missing subnet data**: Ensure spoke deployment has completed successfully
4. **Template variable substitution**: Check GitHub Actions workflow logs for detailed debug output

See the [GitHub Actions Setup Guide](GITHUB_ACTIONS_SETUP.md) for detailed troubleshooting steps.

## Related Documentation

- [Spoke Deployment System](../spokedeployment-tf/Docs/HowToUseSpokeDeployment.md)
- [GitHub Repository Extension](../terraform-azurerm-extension-gh-repo/README.md)
- [Integration Resources Module](../terraform-azurerm-integration-resources/README.md)