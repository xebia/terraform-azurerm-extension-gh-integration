# GitHub Actions Setup for Integration Repositories

## Required GitHub Variables and Secrets

When the extension creates an integration repository with GitHub Actions workflow, you need to configure the following in the repository settings:

### GitHub Variables (for visibility in logs)

Navigate to **Settings → Secrets and variables → Actions → Variables tab** and add:

| Variable Name | Description | Example Value |
|---------------|-------------|---------------|
| `TF_STATE_RESOURCE_GROUP` | Resource group containing Terraform state storage | `rg-terraform-state-prod` |
| `TF_STATE_STORAGE_ACCOUNT` | Storage account name for Terraform state | `stterraformstateprod` |
| `TF_STATE_CONTAINER` | Blob container for state files | `tfstate` |

### GitHub Secrets (for sensitive data)

Navigate to **Settings → Secrets and variables → Actions → Secrets tab** and add:

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `ARM_CLIENT_ID` | Azure AD application client ID | From your Azure AD app registration |
| `ARM_CLIENT_SECRET` | Azure AD application client secret | From your Azure AD app registration |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID | From Azure portal or `az account show` |
| `ARM_TENANT_ID` | Azure AD tenant ID | From Azure portal or `az account show` |

## Why Variables vs Secrets?

### Variables (Visible in Logs) ✅
- **Storage account name**: Not sensitive, helps with debugging
- **Resource group name**: Not sensitive, helps with debugging  
- **Container name**: Not sensitive, helps with debugging

### Secrets (Hidden in Logs) 🔒
- **Client ID**: Sensitive authentication data
- **Client secret**: Highly sensitive authentication data
- **Subscription ID**: Sensitive subscription identifier
- **Tenant ID**: Sensitive tenant identifier

## Troubleshooting DNS Issues

If you encounter DNS lookup errors for storage accounts (like `spoketerraformstateprod.blob.core.windows.net` not found), the visible variable values in logs help identify:

1. **Correct storage account name**: Check if the name matches the actual Azure resource
2. **Naming conflicts**: Verify the storage account name is globally unique
3. **Resource group**: Ensure the state storage exists in the specified resource group
4. **Network access**: Verify the storage account allows access from GitHub Actions runners

## Example Debug Output

With variables, you'll see clear debug information in workflow logs:

```
Backend configuration:
Resource Group: rg-terraform-state-prod
Storage Account: spoketerraformstateprod
Container: tfstate
Key: spoke-dev-integration.tfstate
All backend configuration variables are properly set
```

This makes it much easier to identify configuration issues compared to redacted secret values.

## Manual Setup Steps

1. **Create Variables**: Add the three Terraform state variables with your actual values
2. **Create Secrets**: Add the four Azure authentication secrets
3. **Test Workflow**: Push a change to trigger the workflow and verify authentication works
4. **Check Logs**: Review the debug output to confirm all variables are correctly set

## Security Considerations

- **Never put sensitive data in variables** - they are visible to anyone with repository read access
- **Use secrets for all authentication credentials** - they are encrypted and hidden in logs
- **Regularly rotate client secrets** - especially if repository access changes
- **Limit secret access** - only give repository access to users who need it

## Common Issues

### DNS Lookup Failures
If you see errors like "no such host spoketerraformstateprod.blob.core.windows.net":
1. Verify the storage account name in `TF_STATE_STORAGE_ACCOUNT` variable
2. Check if the storage account exists in Azure
3. Ensure the storage account name follows Azure naming rules (lowercase, no special characters)

### Authentication Failures
If you see "authentication failed" errors:
1. Verify all four ARM_* secrets are set correctly
2. Check that the service principal has Contributor access to the subscription
3. Ensure the client secret hasn't expired

### Missing Variables
If the workflow shows "ERROR: TF_STATE_* variable is not set!":
1. Check that all three variables are created in the repository settings
2. Verify variable names match exactly (case-sensitive)
3. Ensure variables have non-empty values