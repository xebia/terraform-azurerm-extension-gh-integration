# Integration Module
# This module creates GitHub repositories with integration workflows and passes spoke data

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

# Get reference to existing GitHub repository (created by gh-repo extension)
# This repository should already exist when this module is called
data "github_repository" "integration_repo" {
  name = var.project_name
  
  # Add dependency to ensure repository exists
  depends_on = []
}

# Note: Federated identity credentials and basic GitHub secrets (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID)
# are already created by the gh-repo extension, so we don't duplicate them here.

# Create integration-specific GitHub secrets for Terraform state backend
resource "github_actions_secret" "tf_state_resource_group" {
  repository      = data.github_repository.integration_repo.name
  secret_name     = "TF_STATE_RESOURCE_GROUP"
  plaintext_value = try(var.spoke_outputs.resource_group_name, "")
}

resource "github_actions_secret" "tf_state_storage_account" {
  repository      = data.github_repository.integration_repo.name
  secret_name     = "TF_STATE_STORAGE_ACCOUNT"
  plaintext_value = try(var.spoke_outputs.storage_account_name, "")
}

resource "github_actions_secret" "tf_state_container" {
  repository      = data.github_repository.integration_repo.name
  secret_name     = "TF_STATE_CONTAINER"
  plaintext_value = "tfstate"  # Standard container name for Terraform state
}

# Create GitHub Actions variables for spoke outputs (non-sensitive data)
resource "github_actions_variable" "spoke_outputs" {
  for_each = local.filtered_outputs
  
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