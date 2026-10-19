# Terraform Azure GitHub Integration Extension

This extension proposes integration Terraform configuration through pull requests in an existing workload repository. It never writes files to the repository's default branch and never merges a pull request. Repository creation belongs to the separate `github` extension.

## Quick Setup

1. Create or select an initialized workload repository using the `github` extension.
2. Configure publisher credentials and run the spoke deployment.
3. Review and merge the integration configuration pull request.
4. Configure GitHub Actions following the [GitHub Actions Setup Guide](GITHUB_ACTIONS_SETUP.md).

## Purpose

This extension is used by the spoke deployment system to:
1. **Configure existing GitHub repositories** for integration workloads (repositories are created by a separate extension)
2. **Propose repository content** with Terraform configurations and spoke data
3. **Propose deployment workflows** via GitHub Actions when missing
4. **Propose spoke configuration updates** for the workload team to review
5. **Pass spoke outputs** as variables for integration resources

## Usage

Run Terraform with PowerShell 7.2 or newer available as `pwsh`. The publisher reads `GH_TOKEN` or `GITHUB_TOKEN` from the apply process. A GitHub App installation token is suitable, but the publisher cannot inherit an App session created inside the Terraform GitHub provider. When applying a saved plan, pass a fresh token at apply time: a token stored in the plan may have been revoked when the preparation job ended. Do not put tokens in committed variable files.

The token needs repository contents and pull requests write permissions, plus permission to update workflows when a missing workflow is proposed (`Workflows: write` for GitHub Apps or the corresponding PAT scope). The App must be installed on the workload repository. Use a token scoped to that repository; no branch-protection bypass is required.

```hcl
module "github_integration" {
  source = "../terraform-azurerm-extension-gh-integration"

  github_repository_name    = "zlm-integration-crm"
  github_api_url            = "https://github.example.com/api/v3"
  spoke_name                = "crm-dev"
  environment               = "dev"
  subscription_id           = var.subscription_id
  key_vault_id              = var.key_vault_id
  key_vault_name            = var.key_vault_name
  integration_module_source = var.integration_module_source
  spoke_outputs             = var.spoke_outputs
}
```

Use the same host and organization in the GitHub provider. `github_api_url` defaults to `https://api.github.com`; Enterprise root URLs are normalized to `/api/v3`. The repository must have an initial commit, normally created by `repository_auto_init = true`. Empty repositories fail with an actionable error instead of writing to the default branch.

### File Ownership

Shared starter files (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `providers.tf`, `backend.tf`, `README.md`, and `.github/workflows/terraform.yml`) are proposed only when missing from the default branch. Existing shared files, including unmodified starter files, are not reset when templates change. Shared template upgrades require a separate workload-reviewed change.

Each spoke proposes its own `config/spoke-outputs-<environment>.tfvars` and `config/<environment>.azurerm.tfbackend`. Existing environment configuration can appear as a replacement in a PR, but is never changed on the default branch without the workload team merging it. Two spokes targeting the same repository must use different environment names; configuration paths are environment-scoped.

### Pull Request Lifecycle

- Proposals have repository/spoke/environment identities and use `xms/integration-*` branches.
- The publisher uses the actual default branch, writes files atomically in one Git tree, and never force-updates a branch.
- An open proposal is reused. Identical deployments create no additional commit or PR; already merged content produces `no_changes`.
- Closing an unmerged PR rejects that desired revision. An unchanged revision is not reopened. Set `proposal_revision` to a new value to explicitly retry, or deploy changed desired content.
- A merged PR does not block future proposals, even if its branch was deleted. Keep the PR body identity marker so the publisher can recognize its proposals.
- Reviewer commits on proposal branches are not overwritten. Merge or resolve those changes before redeploying. Deleting an open proposal branch requires closing the PR before retrying.
- Branch races fail safely and can be retried. Serialize deployments for the same spoke; different environments use different proposal branches. When two environments bootstrap before either PR merges, refresh the second proposal after merging the first to preserve shared files.

The `terraform_data.repository_proposal` resource is intentionally replaced on every apply so remote PR lifecycle changes are checked even when Terraform inputs do not change. This creates a planned replacement, not repeated repository changes. The script reports the PR URL or no-change/rejected status; Terraform may suppress provisioner output when sensitive inputs are used. PRs are visible in the workload repository.

Environment variables and secrets remain Terraform-managed. Removing this extension does not delete repository files or proposals. This does not change the repository-owning `github` extension's destroy behavior.

## Upgrade From Direct File Management

Terraform 1.9 or newer is required. Keep the same module address when upgrading. Ten `removed` blocks use `destroy = false` to relinquish the former `github_repository_file` resources without deleting remote files, including resources from partially completed deployments.

1. Back up each spoke's Terraform state using your protected state-backup procedure. State contains secrets; do not attach it to issues or PRs.
2. Confirm PowerShell, token permissions, and the Enterprise endpoint before deployment.
3. Review each spoke's plan. Existing file resources must say they will no longer be managed and **will not be destroyed**. Reject a plan containing repository-file deletion or replacement on the default branch.
4. Apply through the normal approved pipeline, then review the generated PR. Merge it only after checking environment configuration and workload customizations.
5. Verify that both dev and acc redeploy successfully and retain their files.

Do not change the old file resources' branch to migrate them: that can destroy files on the original branch. Do not remove the migration blocks until all consuming states have upgraded. Do not roll back to direct-file management without a reviewed state and ownership migration.

The spoke-canvas repository contains a local copy under `infra/modules/extensions/gh_integration`; update and release that copy with this module. Its caller passes the workload provider and configured GitHub endpoint. The generated workflow's existing `acceptance` naming is not changed by this migration; workload teams using `acc` must align the reviewed workflow with their environment names.

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
| `github_repository_name` | Existing workload repository | `string` | n/a | yes |
| `github_api_url` | REST API endpoint matching the provider host | `string` | `https://api.github.com` | no |
| `github_token` | Sensitive token for GitHub provider resources and environment secret; the publisher uses apply-time `GH_TOKEN` or `GITHUB_TOKEN` | `string` | `""` | no |
| `proposal_revision` | Explicit retry identifier after rejection | `string` | `""` | no |
| `environment` | Environment used in configuration paths | `string` | From spoke outputs, otherwise `dev` | no |
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
| terraform | >= 1.9 |
| github | ~> 6.0 |
| PowerShell | >= 7.2 on the Terraform runner |

## Templates

The extension uses template files to generate repository content:

- `spoke-outputs.tfvars.tpl` - Environment spoke configuration
- `backend-config.tfbackend.tpl` - Environment backend settings
- `main.tf.tpl`, `variables.tf.tpl`, etc. - Terraform configuration templates

## GitHub Actions Configuration

After the configuration PR is merged, the workload team can use the proposed workflow. Review its stages, environment names, and authentication settings before running it.

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

## Validation

```sh
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
pwsh -NoProfile -Command 'Invoke-Pester -Path ./tests/Publish-IntegrationProposal.Tests.ps1 -Output Detailed'
```

Terraform tests use mocked providers and plan only. PowerShell tests mock the GitHub API and cover customizations, independent dev/acc proposals, PR reuse, rejection, merge recovery, branch races, and file-retention declarations. Before production rollout, test two independent spoke states against a sandbox repository and inspect the real migration plans. Local mocked tests do not certify customer-state migration or GHES permissions.

## Related Documentation

- [GitHub Actions Setup Guide](GITHUB_ACTIONS_SETUP.md)