# Basic Integration Example

This example shows how to use the GitHub integration module with spoke deployment outputs.

## Usage

```hcl
module "spoke_integration" {
  source = "github.com/xebia/terraform-azurerm-extension-gh-integration"

  # GitHub configuration
  github_organization = "xebia"
  github_token        = var.github_token

  # Project configuration
  project_name = "my-project-integration"

  # Spoke outputs from the spoke deployment
  spoke_outputs = {
    spoke_name            = "my-project-spoke"
    resource_group_name   = "rg-my-project-spoke-dev"
    location              = "West Europe"
    environment           = "dev"
    subnet_id             = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-my-project-spoke-dev/providers/Microsoft.Network/virtualNetworks/vnet-my-project/subnets/default"
    tags = {
      "Environment" = "dev"
      "Project"     = "my-project"
      "Owner"       = "platform-team"
    }
  }

  # Azure configuration
  azure_subscription_id       = "12345678-1234-1234-1234-123456789012"
  azure_tenant_id            = "87654321-4321-4321-4321-210987654321"
  service_principal_client_id = "abcdef12-3456-7890-abcd-ef1234567890"
}
```

## Variables

Create a `terraform.tfvars` file:

```hcl
# GitHub Configuration
github_organization = "your-github-org"
github_token        = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Project Configuration
project_name = "my-integration-project"

# Azure Configuration
azure_tenant_id             = "12345678-1234-1234-1234-123456789012"
azure_subscription_id       = "87654321-4321-4321-4321-210987654321"
service_principal_client_id  = "abcdef12-3456-7890-abcd-ef1234567890"

# Spoke outputs (would typically come from spoke deployment)
spoke_outputs = {
  spoke_name            = "example-spoke"
  resource_group_name   = "rg-example-spoke-dev"
  location              = "West Europe"
  environment           = "dev"
  subnet_id             = "/subscriptions/.../subnets/default"
  tags = {
    "Environment" = "dev"
    "Project"     = "example"
  }
}
```

## Expected Results

The module will create:

1. **GitHub Repository** named `my-integration-project`
2. **Terraform Files** populated with spoke data
3. **GitHub Actions Workflow** for automated deployment
4. **OIDC Federated Identity Credentials** for secure authentication
5. **Repository Secrets** for Azure authentication

The generated repository will contain:
- Integration resources (Storage Account, Key Vault, Private Endpoints)
- Terraform configuration files with spoke-specific values
- GitHub Actions workflow for CI/CD
- Documentation with spoke integration details