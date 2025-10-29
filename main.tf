# Integration Module
# This module creates GitHub repositories with integration workflows and passes spoke data

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Data sources to read template files from local templates directory
data "local_file" "main_tf_template" {
  filename = "${path.module}/templates/main.tf.tpl"
}

data "local_file" "variables_tf_template" {
  filename = "${path.module}/templates/variables.tf.tpl"
}

data "local_file" "outputs_tf_template" {
  filename = "${path.module}/templates/outputs.tf.tpl"
}

data "local_file" "terraform_tfvars_template" {
  filename = "${path.module}/templates/terraform.tfvars.tpl"
}

data "local_file" "versions_tf_template" {
  filename = "${path.module}/templates/versions.tf.tpl"
}

data "local_file" "providers_tf_template" {
  filename = "${path.module}/templates/providers.tf.tpl"
}

data "local_file" "terraform_workflow_template" {
  filename = "${path.module}/templates/.github/workflows/terraform.yml.tpl"
}

data "local_file" "readme_template" {
  filename = "${path.module}/templates/README.md.tpl"
}

# Get the existing Azure AD application (service principal)
data "azuread_application" "spoke_app" {
  client_id = var.service_principal_client_id
}

# Get reference to existing GitHub repository (created by gh-repo extension)
data "github_repository" "integration_repo" {
  name = var.project_name
}

# Create federated identity credential for main branch
resource "azuread_application_federated_identity_credential" "integration_main" {
  application_id = data.azuread_application.spoke_app.id
  display_name   = "${var.project_name}-main-federated-credential"
  description    = "Federated identity credential for ${var.project_name} main branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = var.github_oidc_issuer
  subject        = "repo:${var.github_organization}/${var.project_name}:ref:refs/heads/main"
}

# Create GitHub repository secrets for Azure authentication
resource "github_actions_secret" "azure_client_id" {
  repository      = data.github_repository.integration_repo.name
  secret_name     = "AZURE_CLIENT_ID"
  plaintext_value = var.service_principal_client_id
}

resource "github_actions_secret" "azure_tenant_id" {
  repository      = data.github_repository.integration_repo.name
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = var.azure_tenant_id
}

resource "github_actions_secret" "azure_subscription_id" {
  repository      = data.github_repository.integration_repo.name
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = var.azure_subscription_id
}

# Create GitHub Actions variables for spoke outputs (non-sensitive data)
resource "github_actions_variable" "spoke_outputs" {
  for_each = {
    for key, value in local.non_sensitive_outputs : key => tostring(value)
  }
  
  repository    = data.github_repository.integration_repo.name
  variable_name = upper("SPOKE_${each.key}")
  value         = each.value
}

# Create terraform.tfvars file content for integration repository
resource "github_repository_file" "terraform_tfvars" {
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = "terraform.tfvars"
  content             = local.terraform_tfvars_content
  commit_message      = "Add spoke configuration variables"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create GitHub Actions workflow for deployment
resource "github_repository_file" "workflow_terraform" {
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = ".github/workflows/terraform.yml"
  content             = local.terraform_workflow_content
  commit_message      = "Add Terraform deployment workflow"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create main.tf template for integration repository
resource "github_repository_file" "main_tf" {
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = "main.tf"
  content             = local.main_tf_content
  commit_message      = "Add main Terraform configuration"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create variables.tf template for integration repository
resource "github_repository_file" "variables_tf" {
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = "variables.tf"
  content             = local.variables_tf_content
  commit_message      = "Add variables configuration"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create outputs.tf template for integration repository
resource "github_repository_file" "outputs_tf" {
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = "outputs.tf"
  content             = local.outputs_tf_content
  commit_message      = "Add outputs configuration"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create versions.tf template for integration repository
resource "github_repository_file" "versions_tf" {
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = "versions.tf"
  content             = local.versions_tf_content
  commit_message      = "Add provider versions configuration"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create providers.tf template for integration repository
resource "github_repository_file" "providers_tf" {
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = "providers.tf"
  content             = local.providers_tf_content
  commit_message      = "Add provider configuration"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create README.md for integration repository
resource "github_repository_file" "readme" {
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = "README.md"
  content             = local.readme_content
  commit_message      = "Add README documentation"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}