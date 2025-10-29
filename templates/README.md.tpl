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

The deployment is configured through the `terraform.tfvars` file, which contains values automatically populated from the spoke deployment:

- `spoke_name`: Name of the associated spoke
- `spoke_resource_group_name`: Resource group containing spoke resources
- `spoke_location`: Azure region for the deployment
- `spoke_tags`: Tags inherited from the spoke deployment

## Customization

You can customize this integration by:

1. **Modifying variables**: Update `terraform.tfvars` for your specific needs
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