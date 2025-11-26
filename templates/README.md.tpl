# ${project_name} Integration

This repository contains Terraform configuration for deploying additional resources that integrate with the **${spoke_name}** spoke deployment.

## Overview

This integration deployment was automatically created by the spoke deployment system and contains resources that extend the functionality of the spoke infrastructure.

## Architecture

The integration includes:
- **Storage Account**: Additional storage for integration workloads
- **Key Vault**: Secure storage for secrets and certificates
- **Private Endpoints**: Secure connectivity to spoke network resources

## Spoke Integration Details

This deployment integrates with the following spoke resources:
- **Spoke Name**: `${spoke_name}`
- **Resource Group**: `${spoke_resource_group_name}`
- **Location**: `${spoke_location}`
- **Environment**: `${environment}`

## Prerequisites

1. **Azure CLI**: Ensure you have Azure CLI installed and authenticated
2. **Terraform**: Version 1.0 or later
3. **Permissions**: You need contributor access to the resource group and subscription

## Deployment

### Using GitHub Actions (Recommended)

This repository is set up with GitHub Actions for automated deployment:

1. **Push to main branch**: Deployments are triggered automatically
2. **Pull Requests**: Plan-only runs for review
3. **Manual dispatch**: Can be triggered manually from the Actions tab

### Local Deployment

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## Configuration

> **Note**: If you have an existing `terraform.tfvars` file from a previous version, please delete it manually as this integration now uses `spoke-outputs.tfvars` for better clarity.

The deployment is configured through the `spoke-outputs.tfvars` file, which contains values automatically populated from the spoke deployment.

### Variables Structure

All spoke data is made available through well-structured variables:

```hcl
# Basic spoke information
variable "spoke_name" { }                    # The spoke deployment name
variable "spoke_resource_group_name" { }     # Spoke resource group
variable "spoke_location" { }                # Azure region
variable "environment" { }                  # Environment (dev, test, prod)
variable "tenant_id" { }                    # Azure tenant ID

# Networking data from spoke
variable "spoke_virtual_networks" { }        # Complete VNet information
variable "spoke_subnets" { }                # All subnet details

# Tags inherited from spoke
variable "spoke_tags" { }                   # All spoke tags
```

### Using Variables in Your Code

The integration provides several ways to access spoke data:

#### 1. Direct Variable Access
```hcl
resource "azurerm_resource_group" "example" {
  name     = "$${spoke_name}-integration"
  location = var.spoke_location
  tags     = var.spoke_tags
}
```

#### 2. Using Local Values (Recommended)
The integration includes helpful local values in `locals.tf`:

```hcl
# Access spoke info easily
local.spoke_info.name              # Spoke name
local.spoke_info.location          # Azure region
local.spoke_info.resource_group    # RG name

# Use enhanced tags with integration context
local.integration_tags             # Spoke tags + integration tags

# Access networking data conveniently
local.networking.primary_vnet_id   # First VNet ID
local.networking.primary_subnet_id # First subnet ID
local.networking.subnet_ids        # All subnet IDs as list

# Find subnets by type
local.subnet_lookup.pe_subnets     # Private endpoint subnets
local.subnet_lookup.web_subnets    # Web subnets
local.subnet_lookup.app_subnets    # App subnets

# Standard naming patterns
local.naming.prefix                # "spoke-name-integration"
local.naming.resource_group_name   # Standard RG name
local.naming.storage_account_name  # Standard SA name
```

#### 3. Advanced Subnet Selection
```hcl
# Create private endpoints in PE subnets
resource "azurerm_private_endpoint" "example" {
  for_each = {
    for idx, subnet in local.subnet_lookup.pe_subnets : 
    subnet.subnet_key => subnet
  }
  
  subnet_id = each.value.subnet_id
  # ... other configuration
}

# Create NSG for each VNet
resource "azurerm_network_security_group" "example" {
  for_each = var.spoke_virtual_networks
  
  name = "$${local.naming.prefix}-$${each.key}-nsg"
  # ... other configuration
}
```

### Basic Configuration
- `spoke_name`: Name of the associated spoke
- `spoke_resource_group_name`: Resource group containing spoke resources
- `spoke_location`: Azure region for the deployment
- `spoke_tags`: Tags inherited from the spoke deployment

### Networking Configuration
The integration includes comprehensive networking information from the spoke deployment:

- `spoke_virtual_networks`: Complete virtual network information with all subnets
- `spoke_subnets`: Simplified list of all subnets for easy access

#### Using Multiple Subnets

You can access specific subnets in several ways:

```hcl
# Access all subnet IDs
locals {
  all_subnet_ids = [for subnet in local.spoke_subnets : subnet.subnet_id]
}

# Find subnet by name pattern
locals {
  web_subnet_id = [
    for subnet in local.spoke_subnets : subnet.subnet_id 
    if contains(split("-", subnet.subnet_name), "web")
  ][0]
}

# Group subnets by virtual network
locals {
  subnets_by_vnet = {
    for vnet_key, vnet in local.spoke_virtual_networks : vnet_key => [
      for subnet in local.spoke_subnets : subnet
      if subnet.vnet_key == vnet_key
    ]
  }
}

# Create resources in multiple subnets
resource "azurerm_private_endpoint" "example" {
  for_each = { for subnet in local.spoke_subnets : subnet.subnet_key => subnet }
  
  name      = "pe-$${each.key}"
  subnet_id = each.value.subnet_id
  # ... other configuration
}
```

## Customization

You can customize this integration by:

1. **Modifying variables**: Update `spoke-outputs.tfvars` for your specific needs
2. **Adding resources**: Extend `main.tf` with additional Azure resources
3. **Updating tags**: Modify tags in the variables file

## Integration with Spoke

This deployment automatically integrates with the spoke infrastructure:

- **Network connectivity** through private endpoints
- **Resource naming** follows spoke conventions
- **Tagging strategy** inherits from spoke deployment
- **RBAC integration** with spoke identity and access management

## Monitoring and Maintenance

- **Resource monitoring**: Integrated with spoke monitoring solutions
- **Backup strategy**: Follows organizational backup policies
- **Security compliance**: Inherits spoke security configurations

## Support

For issues related to this integration deployment:

1. Check the GitHub Actions logs for deployment issues
2. Review the Terraform state for resource status
3. Contact the platform team for spoke-related issues

## Related Documentation

- [Spoke Deployment Documentation](../spokedeployment-tf/Docs/HowToUseSpokeDeployment.md)
- [GitHub Extension Guide](../terraform-azurerm-extension-gh-repo/README.md)
- [Integration Architecture](./docs/architecture.md)

---
*This integration was automatically generated on ${timestamp} for spoke deployment: ${spoke_name}*