locals {
  # Separate sensitive and non-sensitive outputs
  non_sensitive_outputs = {
    spoke_name                   = try(var.spoke_outputs.spoke_name, "")
    environment                  = try(var.spoke_outputs.environment, "")
    subscription_id              = try(var.spoke_outputs.subscription_id, "")
    resource_group_name          = try(var.spoke_outputs.resource_group_name, "")
    location                     = try(var.spoke_outputs.location, "")
    storage_account_name         = try(var.spoke_outputs.storage_account_name, "")
    key_vault_name              = try(var.spoke_outputs.key_vault_name, "")
    log_analytics_workspace_name = try(var.spoke_outputs.log_analytics_workspace_name, "")
    subnet_id                   = try(var.spoke_outputs.subnet_id, "")
  }

  # Template variables for populating template files
  template_vars = {
    project_name                = var.project_name
    spoke_name                  = try(var.spoke_outputs.spoke_name, var.project_name)
    spoke_resource_group_name   = try(var.spoke_outputs.resource_group_name, "")
    spoke_location              = try(var.spoke_outputs.location, "West Europe")
    spoke_subnet_id             = try(var.spoke_outputs.subnet_id, "")
    tenant_id                   = var.azure_tenant_id
    environment                 = try(var.spoke_outputs.environment, "dev")
    integration_purpose         = "Additional resources for ${try(var.spoke_outputs.spoke_name, var.project_name)}"
    spoke_tags                  = jsonencode(try(var.spoke_outputs.tags, {}))
    timestamp                   = timestamp()
  }

  # Generate content from templates using data sources
  terraform_tfvars_content = templatestring(data.local_file.terraform_tfvars_template.content, local.template_vars)
  main_tf_content          = templatestring(data.local_file.main_tf_template.content, local.template_vars)
  variables_tf_content     = templatestring(data.local_file.variables_tf_template.content, local.template_vars)
  outputs_tf_content       = templatestring(data.local_file.outputs_tf_template.content, local.template_vars)
  versions_tf_content      = data.local_file.versions_tf_template.content
  providers_tf_content     = data.local_file.providers_tf_template.content
  terraform_workflow_content = templatestring(data.local_file.terraform_workflow_template.content, local.template_vars)
  readme_content           = templatestring(data.local_file.readme_template.content, local.template_vars)
}