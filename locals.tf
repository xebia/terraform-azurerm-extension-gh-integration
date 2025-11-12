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

  # Process virtual networks and subnets information
  virtual_networks = try(var.spoke_outputs.virtual_networks, {})
  
  # Extract all subnet IDs for easier access
  all_subnet_ids = flatten([
    for vnet_key, vnet in local.virtual_networks : [
      for subnet_key, subnet in try(vnet.subnets, {}) : {
        vnet_name        = vnet.name
        vnet_key         = vnet_key
        subnet_name      = subnet.name
        subnet_key       = subnet_key
        subnet_id        = subnet.id
        address_prefixes = try(subnet.address_prefixes, [])
      }
    ]
  ])
  
  # Get the first subnet ID (for backward compatibility)
  primary_subnet_id = length(local.all_subnet_ids) > 0 ? local.all_subnet_ids[0].subnet_id : ""

  # Filter out empty values for GitHub Actions variables (GitHub requires non-empty values)
  filtered_outputs = {
    for key, value in local.non_sensitive_outputs : key => value
    if value != null && value != ""
  }

  # Template variables for populating template files
  template_vars = {
    project_name                = var.project_name
    spoke_name                  = try(var.spoke_outputs.spoke_name, var.project_name)
    spoke_resource_group_name   = try(var.spoke_outputs.resource_group_name, "default-rg")
    spoke_location              = try(var.spoke_outputs.location, "West Europe")
    tenant_id                   = var.azure_tenant_id
    environment                 = try(var.spoke_outputs.environment, "dev")
    integration_purpose         = "Additional resources for ${try(var.spoke_outputs.spoke_name, var.project_name)}"
    spoke_tags                  = jsonencode(try(var.spoke_outputs.tags, {}))
    spoke_virtual_networks      = jsonencode(local.virtual_networks)
    spoke_subnets               = jsonencode(local.all_subnet_ids)
    timestamp                   = timestamp()
    
    # Additional variables for complex template expressions
    spoke_virtual_networks_json = jsonencode(local.virtual_networks)
    spoke_subnets_json          = jsonencode(local.all_subnet_ids)
  }

  # Generate content from templates using data sources
  terraform_tfvars_content = templatestring(data.local_file.terraform_tfvars_template.content, local.template_vars)
  main_tf_content          = templatestring(data.local_file.main_tf_template.content, local.template_vars)
  variables_tf_content     = templatestring(data.local_file.variables_tf_template.content, local.template_vars)
  outputs_tf_content       = templatestring(data.local_file.outputs_tf_template.content, local.template_vars)
  versions_tf_content      = data.local_file.versions_tf_template.content
  providers_tf_content     = data.local_file.providers_tf_template.content
  backend_tf_content       = data.local_file.backend_tf_template.content
  terraform_workflow_content = templatestring(data.local_file.terraform_workflow_template.content, local.template_vars)
  readme_content           = templatestring(data.local_file.readme_template.content, local.template_vars)
}