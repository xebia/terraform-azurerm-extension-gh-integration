
# Integration Module
# This module proposes integration repository content and passes spoke data

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

data "local_file" "backend_config_template" {
  filename = "${path.module}/templates/backend-config.tfbackend.tpl"
}

# Get reference to existing GitHub repository (created by gh-repo extension)
# This repository should already exist when this module is called
data "github_repository" "integration_repo" {
  name = local.actual_repository_name
}

locals {
  integration_module_source_parts = regex("^.*https://[^/]+/(?P<owner>[^/]+)/(?P<repository>[^/?]+)", var.integration_module_source)

  # Backwards compatibility: extract values from either new variables or legacy spoke_outputs
  actual_spoke_name = coalesce(
    var.spoke_name,
    try(var.spoke_outputs.spoke_name, ""),
    var.project_name,
    ""
  )

  actual_workload_name = coalesce(
    try(var.spoke_outputs.workload_short_name, ""),
    local.actual_spoke_name
  )

  actual_tf_state_resource_group = coalesce(
    var.terraform_state_resource_group,
    try(var.spoke_outputs.terraform_state_resource_group, ""),
    local.actual_spoke_resource_group_name
  )

  actual_tf_state_storage_account = coalesce(
    var.terraform_state_storage_account != "" ? var.terraform_state_storage_account : null,
    try(var.spoke_outputs.terraform_state_storage_account, ""),
    try(var.spoke_outputs.storage_account_name, ""),
    "stterraformstate${replace(local.actual_spoke_name, "-", "")}"
  )

  actual_tf_state_container = coalesce(
    var.terraform_state_container,
    try(var.spoke_outputs.terraform_state_container, ""),
    "tfstate"
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

  actual_repository_name = var.github_repository_name

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
    spoke_config              = var.spoke_config
    project_name              = local.actual_spoke_name
    integration_module_source = var.integration_module_source
    path                      = path.module
  })

  variables_tf_content = data.local_file.variables_tf_template.content
  outputs_tf_content   = data.local_file.outputs_tf_template.content
  versions_tf_content  = data.local_file.versions_tf_template.content
  providers_tf_content = data.local_file.providers_tf_template.content
  backend_tf_content = templatestring(data.local_file.backend_tf_template.content, {
    spoke_name      = local.actual_spoke_name
    subscription_id = local.actual_subscription_id
  })
  backend_config_content = templatestring(data.local_file.backend_config_template.content, {
    resource_group_name  = local.actual_tf_state_resource_group
    storage_account_name = local.actual_tf_state_storage_account
    container_name       = local.actual_tf_state_container
    key                  = "${local.actual_workload_name}-${local.actual_environment}-integration.tfstate"
  })
  readme_content = templatestring(data.local_file.readme_template.content, {
    project_name              = local.actual_spoke_name
    spoke_name                = local.actual_spoke_name
    repository_name           = local.actual_repository_name
    spoke_resource_group_name = local.actual_spoke_resource_group_name
    spoke_location            = local.actual_spoke_location
    environment               = local.actual_environment
  })
  terraform_workflow_content = templatestring(data.local_file.terraform_workflow_template.content, {
    project_name      = local.actual_spoke_name
    spoke_name        = local.actual_spoke_name
    workload_name     = local.actual_workload_name
    environment       = local.actual_environment
    runner_label      = var.default_runner_label
    module_owner      = local.integration_module_source_parts.owner
    module_repository = trimsuffix(local.integration_module_source_parts.repository, ".git")
  })
}

# Create GitHub Actions secrets for sensitive authentication data
resource "github_actions_environment_secret" "gh_integration_token" {
  repository      = var.github_repository_name
  environment     = local.actual_environment
  secret_name     = "GH_INTEGRATION_TOKEN"
  plaintext_value = var.github_token
}

# Create GitHub Actions variables for spoke outputs
resource "github_actions_environment_variable" "spoke_outputs" {
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
  environment   = local.actual_environment
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
