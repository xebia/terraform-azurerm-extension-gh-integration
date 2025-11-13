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

data "local_file" "spoke_outputs_tfvars_template" {
  filename = "${path.module}/templates/spoke-outputs.tfvars.tpl"
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

data "local_file" "backend_tf_template" {
  filename = "${path.module}/templates/backend.tf.tpl"
}

# Get reference to existing GitHub repository (created by gh-repo extension)
# This repository should already exist when this module is called
data "github_repository" "integration_repo" {
  name = coalesce(var.repository_name, var.project_name)
}

# Check if main.tf already exists to determine if this is first deployment or update
data "github_repository_file" "existing_main_tf" {
  repository = data.github_repository.integration_repo.name
  branch     = "main"
  file       = "main.tf"
}

# Determine if this is first deployment (main.tf doesn't exist) or update (main.tf exists)
locals {
  is_first_deployment = data.github_repository_file.existing_main_tf.content == null

  # Generate spoke-outputs.tfvars content using the template
  spoke_outputs_tfvars_content = templatestring(data.local_file.spoke_outputs_tfvars_template.content, {
    spoke_name                    = var.spoke_name
    subscription_id              = var.subscription_id
    spoke_resource_group_name    = var.spoke_resource_group_name
    spoke_location               = var.spoke_location
    key_vault_id                 = var.key_vault_id
    key_vault_name               = var.key_vault_name
    virtual_network_id           = var.virtual_network_id
    virtual_network_name         = var.virtual_network_name
    subnet_ids                   = var.subnet_ids
    subnet_names                 = var.subnet_names
    log_analytics_workspace_id   = var.log_analytics_workspace_id
    application_insights_id      = var.application_insights_id
  })

  # Generate other template content (only for first deployment)
  main_tf_content = templatestring(data.local_file.main_tf_template.content, {
    spoke_name = var.spoke_name
  })
  
  variables_tf_content = data.local_file.variables_tf_template.content
  outputs_tf_content = data.local_file.outputs_tf_template.content  
  versions_tf_content = data.local_file.versions_tf_template.content
  providers_tf_content = data.local_file.providers_tf_template.content
  backend_tf_content = templatestring(data.local_file.backend_tf_template.content, {
    spoke_name = var.spoke_name
    subscription_id = var.subscription_id
  })
  readme_content = templatestring(data.local_file.readme_template.content, {
    spoke_name = var.spoke_name
    repository_name = coalesce(var.repository_name, var.project_name)
  })
  terraform_workflow_content = data.local_file.terraform_workflow_template.content
}

# Create spoke-outputs.tfvars file content for integration repository
resource "github_repository_file" "spoke_outputs_tfvars" {
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = "spoke-outputs.tfvars"
  content             = local.spoke_outputs_tfvars_content
  commit_message      = local.is_first_deployment ? "Add spoke configuration variables" : "chore: update spoke configuration variables from spoke deployment"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create GitHub Actions workflow for deployment
resource "github_repository_file" "workflow_terraform" {
  count = local.is_first_deployment ? 1 : 0
  
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
  count = local.is_first_deployment ? 1 : 0
  
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
  count = local.is_first_deployment ? 1 : 0
  
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
  count = local.is_first_deployment ? 1 : 0
  
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
  count = local.is_first_deployment ? 1 : 0
  
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
  count = local.is_first_deployment ? 1 : 0
  
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = "providers.tf"
  content             = local.providers_tf_content
  commit_message      = "Add provider configuration"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create backend.tf template for integration repository
resource "github_repository_file" "backend_tf" {
  count = local.is_first_deployment ? 1 : 0
  
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = "backend.tf"
  content             = local.backend_tf_content
  commit_message      = "Add backend configuration with Azure AD auth"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create README.md for integration repository
resource "github_repository_file" "readme" {
  count = local.is_first_deployment ? 1 : 0
  
  repository          = data.github_repository.integration_repo.name
  branch              = "main"
  file                = "README.md"
  content             = local.readme_content
  commit_message      = "Add README documentation"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}