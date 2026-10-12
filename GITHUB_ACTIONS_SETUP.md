# GitHub Actions Setup for Integration Repositories

The generated workflow runs Terraform for `dev`, `acceptance`, and `prod`. It uses a GitHub App installation token to download the private Terraform module selected by `integration_module_source`, and Azure OIDC to authenticate to Azure.

## GitHub App Access To The Private Module

The generated workflow uses the same Cloud Platform GitHub App as the platform deployment workflows. Do not create a separate App for integration repositories. The App must be installed with access to the organization that owns `xms-integration-platform-modules-code`, and its installation must have **Contents: Read-only** access to that repository so Terraform can download the private module. Confirm the App installation is approved and includes the module repository.

The workflow creates a short-lived installation token in each deployment job and requests access only to the configured module repository with `Contents: read`. The token is used by Git to clone the module during `terraform init`; it is not the Azure credential and does not need to be stored as a long-lived token.

## Organization Actions Variable And Secret

The workflow reads the shared Cloud Platform App credentials from organization-level Actions variables and secrets:

| Type | Name | Value |
|------|------|-------|
| Organization variable | `cloud_platform_gh_app_id` | The numeric Cloud Platform GitHub App ID |
| Organization secret | `cloud_platform_gh_app_private_key` | The complete contents of the Cloud Platform GitHub App private key PEM file |

In the organization, open **Settings → Secrets and variables → Actions**. Make the variable and secret available to each integration repository that runs this workflow. If organization policy restricts access to selected repositories, add each integration repository to both access lists. When a new spoke is created with the GitHub repository and integration extensions enabled, include its integration repository before running its deployment workflow. These names match the credentials used by the platform deployment workflows.

Treat the private key as a credential. Do not commit it to a repository or place it in an Actions variable. If it is exposed, revoke the key in the GitHub App settings and generate a replacement.

## Azure OIDC Configuration

The workflow uses Azure federated identity credentials; it does not use an Azure client secret. Configure these Actions secrets for the workflow's `dev`, `acceptance`, and `prod` environments, or provide them as organization/repository secrets available to those jobs:

| Secret name | Value |
|-------------|-------|
| `AZURE_CLIENT_ID` | Client ID of the Azure application/service principal configured for workload identity federation |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_TENANT_ID` | Microsoft Entra tenant ID |

Configure federated credentials in Microsoft Entra ID for the GitHub repository and the relevant GitHub environments. Grant the identity the required Azure resource permissions and Azure Blob data-plane access to the Terraform state container.

## Terraform State Configuration

The extension writes the backend settings into `config/<environment>.azurerm.tfbackend` when it populates the integration repository. The workflow passes that file to `terraform init`; it does not read `TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT`, or `TF_STATE_CONTAINER` Actions variables. Ensure the generated backend points to an existing storage account and container, and that the Azure identity can access the state blob.

## Running The Workflow

The generated workflow is triggered manually with **Actions → Terraform Deploy → Run workflow**. It runs the stages in order: `dev`, then `acceptance`, then `prod`. Configure GitHub environment protection rules, such as required reviewers, if approvals are required before higher environments deploy.

## Troubleshooting Private Module Access

- **The token action cannot create a token:** Check that the App is installed on the module repository's owning organization and that the App ID and private key are correct and available to the integration repository.
- **The token is created but `terraform init` cannot clone the module:** Confirm the App installation includes `xms-integration-platform-modules-code` and has **Contents: Read-only** permission. Also check that `integration_module_source` uses the correct owner, repository, and ref.
- **An Actions value is empty:** Confirm the organization variable/secret's repository access policy includes the integration repository. Organization secrets and variables must be available to all three environment jobs.
- **Azure authentication or state access fails:** Check the Azure OIDC federated credentials, the three `AZURE_*` secrets, Azure role assignments, and Storage Blob data-plane permissions. These are separate from the GitHub App permissions.