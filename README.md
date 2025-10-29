# Terraform Azure GitHub Integration Module

This module creates GitHub repositories with integration workflows and populates them with spoke deployment data for additional resource deployments.

## Purpose

This module is used by the spoke deployment system to:

1. **Create GitHub repositories** for integration workloads
2. **Populate repositories** with Terraform configurations using spoke data
3. **Set up OIDC authentication** for secure GitHub Actions → Azure integration
4. **Configure automated deployment workflows** via GitHub Actions
5. **Pass spoke outputs** as variables for integration resources

## Usage

```hcl
module "spoke_integration" {
  source = "github.com/xebia/terraform-azurerm-extension-gh-integration"

  # GitHub configuration
  github_organization = "xebia"
  github_token        = var.github_token

  # Project configuration
  project_name = "my-project-integration"
  spoke_outputs = {
    spoke_name                = "my-project-spoke"
    spoke_resource_group_name = "rg-my-project-spoke-dev"
    spoke_location            = "West Europe"
    spoke_tags = {
      "Environment" = "dev"
      "Project"     = "my-project"
      "Owner"       = "platform-team"
    }
    spoke_subnet_id           = "/subscriptions/.../subnets/default"
    tenant_id                 = "87654321-4321-4321-4321-210987654321"
    environment               = "dev"
  }

  # Azure configuration
  azure_subscription_id       = "12345678-1234-1234-1234-123456789012"
  azure_tenant_id            = "87654321-4321-4321-4321-210987654321"
  service_principal_client_id = "abcdef12-3456-7890-abcd-ef1234567890"
}
```

## What This Creates

1. **GitHub Repository** with proper settings and topics
2. **Terraform Files** populated with spoke data:
   - `main.tf` - Integration resources (Storage, Key Vault, Private Endpoints)
   - `variables.tf` - Variable definitions with spoke defaults
   - `outputs.tf` - Output definitions for integration resources
   - `terraform.tfvars` - Values populated from spoke deployment
   - `versions.tf` - Provider version constraints
   - `providers.tf` - Provider configuration
3. **GitHub Actions Workflow** for automated deployment
4. **OIDC Federated Identity Credentials** for secure authentication
5. **Repository Secrets** for Azure authentication

## Template Configuration

The module uses the `terraform-azurerm-extension-gh-integration-template` repository as the source for template files that are copied and populated with spoke data.

## Integration Resources

The generated repository includes example integration resources:

- **Storage Account**: Additional storage with spoke network integration
- **Key Vault**: Secure storage for secrets and certificates
- **Private Endpoints**: Secure connectivity to spoke networks
- **Resource Naming**: Follows spoke naming conventions
- **Tagging**: Inherits and extends spoke tags

## Security

- **OIDC Authentication**: No long-lived credentials stored in GitHub
- **Federated Identity**: Direct Azure AD integration via OIDC
- **Least Privilege**: Repository-specific service principals
- **Secret Management**: Uses Azure Key Vault for sensitive data

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `github_organization` | GitHub organization name | `string` | n/a | yes |
| `github_token` | GitHub Personal Access Token | `string` | n/a | yes |
| `project_name` | Name of the integration project | `string` | n/a | yes |
| `spoke_outputs` | All outputs from spoke deployment | `any` | `{}` | yes |
| `azure_tenant_id` | Azure tenant ID | `string` | n/a | yes |
| `azure_subscription_id` | Azure subscription ID | `string` | n/a | yes |
| `service_principal_client_id` | Azure service principal client ID | `string` | n/a | yes |
| `github_repo_visibility` | Repository visibility | `string` | `"private"` | no |
| `github_oidc_issuer` | GitHub OIDC issuer URL | `string` | `"https://token.actions.githubusercontent.com"` | no |
| `template_repository` | Template repository name | `string` | `"terraform-azurerm-extension-gh-integration-template"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `integration_repository_name` | Name of the created integration repository |
| `integration_repository_url` | URL of the integration repository |
| `integration_repository_clone_url` | Clone URL of the integration repository |
| `federated_credential_main_id` | ID of the federated identity credential |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |
| azuread | ~> 2.0 |
| github | ~> 6.0 |

## Related Documentation

- [Spoke Deployment System](../spokedeployment-tf/Docs/HowToUseSpokeDeployment.md)
- [Template Repository](../terraform-azurerm-extension-gh-integration-template/README.md)
- [GitHub Extension Guide](../terraform-azurerm-extension-gh-repo/README.md)