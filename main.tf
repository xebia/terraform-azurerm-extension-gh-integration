
# Integration Module
# This module creates GitHub repositories with integration workflows and passes spoke data

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

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
  name = local.actual_repository_name
}

locals {
  # Backwards compatibility: extract values from either new variables or legacy spoke_outputs
  actual_spoke_name = coalesce(
    var.spoke_name,
    try(var.spoke_outputs.spoke_name, ""),
    var.project_name,
    ""
  )

  actual_subscription_id = coalesce(
    var.subscription_id,
    var.azure_subscription_id,
    try(var.spoke_outputs.subscription_id, ""),
    ""
  )

  actual_spoke_resource_group_name = coalesce(
    var.spoke_resource_group_name != "" ? var.spoke_resource_group_name : null,
    try(var.spoke_outputs.spoke_resource_group_name != "" ? var.spoke_outputs.spoke_resource_group_name : null, null),
    # Try to get resource group name from spoke outputs in different possible formats
    try(var.spoke_outputs.resourcegroup.weu.resResourceGroup.name, null),
    try(var.spoke_outputs.resource_group_name, null),
    try(var.spoke_outputs.rg_name, null),
    "${local.actual_spoke_name}-rg"
  )

  actual_spoke_location = coalesce(
    var.spoke_location != "" ? var.spoke_location : null,
    try(var.spoke_outputs.spoke_location != "" ? var.spoke_outputs.spoke_location : null, null),
    "West Europe"
  )

  actual_environment = coalesce(
    var.environment != "" ? var.environment : null,
    try(var.spoke_outputs.environment != "" ? var.spoke_outputs.environment : null, null),
    "dev"
  )

  actual_key_vault_id = coalesce(
    var.key_vault_id != "" ? var.key_vault_id : null,
    try(var.spoke_outputs.key_vault_id != "" ? var.spoke_outputs.key_vault_id : null, null),
    ""
  )

  actual_key_vault_name = coalesce(
    var.key_vault_name != "" ? var.key_vault_name : null,
    try(var.spoke_outputs.key_vault_name != "" ? var.spoke_outputs.key_vault_name : null, null),
    ""
  )

  actual_virtual_network_id = try(
    coalesce(
      var.virtual_network_id != "" ? var.virtual_network_id : null,
      var.spoke_outputs.virtual_network_id != "" ? var.spoke_outputs.virtual_network_id : null
    ),
    ""
  )

  actual_virtual_network_name = coalesce(
    var.virtual_network_name != "" ? var.virtual_network_name : null,
    try(var.spoke_outputs.virtual_network_name != "" ? var.spoke_outputs.virtual_network_name : null, null),
    "${local.actual_spoke_name}-vnet"
  )

  # Repository name: use repository_name if provided, otherwise derive from spoke_name
  actual_repository_name = coalesce(
    var.repository_name,
    "${local.actual_spoke_name}-repo",
    var.project_name,
    "integration-repo"
  )

  # Generate spoke-outputs.tfvars content using the new spoke_config object format
  spoke_outputs_tfvars_content = templatestring(data.local_file.spoke_outputs_tfvars_template.content, {
    spoke_name                   = local.actual_spoke_name
    subscription_id              = local.actual_subscription_id
    spoke_resource_group_name    = local.actual_spoke_resource_group_name
    spoke_location               = local.actual_spoke_location
    key_vault_id                 = local.actual_key_vault_id
    key_vault_name               = local.actual_key_vault_name
    storage_account_id           = try(var.spoke_outputs.storage_account_id, "")
    storage_account_name         = try(var.spoke_outputs.storage_account_name, "")
    virtual_network_id           = local.actual_virtual_network_id
    virtual_network_name         = local.actual_virtual_network_name
    subnet_ids                   = try(var.spoke_outputs.subnet_ids, var.subnet_ids, {})
    subnet_names                 = try(var.spoke_outputs.subnet_names, var.subnet_names, {})
    log_analytics_workspace_id   = try(coalesce(var.spoke_outputs.log_analytics_workspace_id, var.log_analytics_workspace_id), var.log_analytics_workspace_id, "")
    log_analytics_workspace_name = try(coalesce(var.spoke_outputs.log_analytics_workspace_name, var.log_analytics_workspace_name), var.log_analytics_workspace_name, "")
    tenant_id                    = data.azurerm_client_config.current.tenant_id
    environment                  = local.actual_environment
  })

  # Generate other template content
  main_tf_content = templatestring(data.local_file.main_tf_template.content, {
    spoke_config = var.spoke_config
    project_name = local.actual_spoke_name
    path         = path.module
  })

  variables_tf_content = data.local_file.variables_tf_template.content
  outputs_tf_content   = data.local_file.outputs_tf_template.content
  versions_tf_content  = data.local_file.versions_tf_template.content
  providers_tf_content = data.local_file.providers_tf_template.content
  backend_tf_content = templatestring(data.local_file.backend_tf_template.content, {
    spoke_name      = local.actual_spoke_name
    subscription_id = local.actual_subscription_id
  })
  readme_content = templatestring(data.local_file.readme_template.content, {
    project_name              = local.actual_spoke_name
    spoke_name                = local.actual_spoke_name
    repository_name           = local.actual_repository_name
    spoke_resource_group_name = local.actual_spoke_resource_group_name
    spoke_location            = local.actual_spoke_location
    environment               = local.actual_environment
    timestamp                 = timestamp()
  })
  terraform_workflow_content = templatestring(data.local_file.terraform_workflow_template.content, {
    project_name = local.actual_spoke_name
    spoke_name   = local.actual_spoke_name
    environment  = local.actual_environment
  })
}

# Create spoke-outputs.tfvars file content for integration repository
resource "github_repository_file" "spoke_outputs_tfvars" {
  repository          = var.github_repository_name
  branch              = "main"
  file                = "spoke-outputs.tfvars"
  content             = local.spoke_outputs_tfvars_content
  commit_message      = "Update spoke configuration variables from spoke deployment"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create GitHub Actions workflow for Terraform
resource "github_repository_file" "workflow_terraform" {
  repository          = var.github_repository_name
  branch              = "main"
  file                = ".github/workflows/terraform.yml"
  content             = local.terraform_workflow_content
  commit_message      = "Update Terraform workflow"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true
}

# Create main.tf template for integration repository
resource "github_repository_file" "main_tf" {
  repository          = var.github_repository_name
  branch              = "main"
  file                = "main.tf"
  content             = local.main_tf_content
  commit_message      = "Add main Terraform configuration"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = false

  # Always ignore content changes to preserve user customizations
  lifecycle {
    ignore_changes = [content, commit_message]
  }
}

# Create variables.tf template for integration repository
resource "github_repository_file" "variables_tf" {
  repository          = var.github_repository_name
  branch              = "main"
  file                = "variables.tf"
  content             = local.variables_tf_content
  commit_message      = "Add variables configuration"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = false

  # Ignore content changes to preserve user customizations
  lifecycle {
    ignore_changes = [content, commit_message]
  }
}

# Create outputs.tf template for integration repository
resource "github_repository_file" "outputs_tf" {
  repository          = var.github_repository_name
  branch              = "main"
  file                = "outputs.tf"
  content             = local.outputs_tf_content
  commit_message      = "Add outputs configuration"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = false

  # Ignore content changes to preserve user customizations
  lifecycle {
    ignore_changes = [content, commit_message]
  }
}

# Create versions.tf template for integration repository
resource "github_repository_file" "versions_tf" {
  repository          = var.github_repository_name
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
  repository          = var.github_repository_name
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
  repository          = var.github_repository_name
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
  repository          = var.github_repository_name
  branch              = "main"
  file                = "README.md"
  content             = local.readme_content
  commit_message      = "Add README documentation"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@automation.local"
  overwrite_on_create = true

  # Ignore content changes to preserve user customizations
  lifecycle {
    ignore_changes = [content, commit_message]
  }
}

# Create GitHub Actions secrets for sensitive authentication data
resource "github_actions_secret" "gh_integration_token" {
  repository      = var.github_repository_name
  secret_name     = "GH_INTEGRATION_TOKEN"
  plaintext_value = var.github_token
}

# Create GitHub Actions variables for Terraform state backend (for debugging visibility)
resource "github_actions_variable" "tf_state_resource_group" {
  repository    = var.github_repository_name
  variable_name = "TF_STATE_RESOURCE_GROUP"
  value = coalesce(
    var.terraform_state_resource_group,
    try(var.spoke_outputs.terraform_state_resource_group, ""),
    local.actual_spoke_resource_group_name
  )
}

resource "github_actions_variable" "tf_state_storage_account" {
  repository    = var.github_repository_name
  variable_name = "TF_STATE_STORAGE_ACCOUNT"
  value = coalesce(
    var.terraform_state_storage_account != "" ? var.terraform_state_storage_account : null,
    try(var.spoke_outputs.terraform_state_storage_account, ""),
    try(var.spoke_outputs.storage_account_name, ""),
    "stterraformstate${replace(local.actual_spoke_name, "-", "")}"
  )
}

resource "github_actions_variable" "tf_state_container" {
  repository    = var.github_repository_name
  variable_name = "TF_STATE_CONTAINER"
  value = coalesce(
    var.terraform_state_container,
    try(var.spoke_outputs.terraform_state_container, ""),
    "tfstate"
  )
}

# Create GitHub Actions variables for spoke outputs
resource "github_actions_variable" "spoke_outputs" {
  for_each = {
    spoke_name           = "SPOKE_SPOKE_NAME"
    subscription_id      = "SPOKE_SUBSCRIPTION_ID"
    resource_group_name  = "SPOKE_RESOURCE_GROUP_NAME"
    location             = "SPOKE_LOCATION"
    environment          = "SPOKE_ENVIRONMENT"
    key_vault_name       = "SPOKE_KEY_VAULT_NAME"
    storage_account_name = "SPOKE_STORAGE_ACCOUNT_NAME"
    storage_account_id   = "SPOKE_STORAGE_ACCOUNT_ID"
    subnet_id            = "SPOKE_SUBNET_ID"
  }

  repository    = var.github_repository_name
  variable_name = each.value
  value = lookup({
    spoke_name           = local.actual_spoke_name
    subscription_id      = local.actual_subscription_id
    resource_group_name  = local.actual_spoke_resource_group_name
    location             = local.actual_spoke_location
    environment          = local.actual_environment
    key_vault_name       = local.actual_key_vault_name
    storage_account_name = try(var.spoke_outputs.storage_account_name, "")
    storage_account_id   = try(var.spoke_outputs.storage_account_id, "")
    subnet_id            = try(var.spoke_outputs.subnet_id, "")
  }, each.key, "")
}
