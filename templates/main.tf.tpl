# Terraform Configuration for ${project_name} Integration

# Data source for current Azure client configuration
data "azurerm_client_config" "this" {}

# Use the integration resources module to create additional resources
module "integration_resources" {
  source = "${integration_module_source}"

  # Main spoke prams from the spoke creation output.
  spoke_config = {
    name                       = var.spoke_config.name
    subscription_id            = var.spoke_config.subscription_id
    resource_group_name        = var.spoke_config.resource_group_name
    location                   = var.spoke_config.location
    tenant_id                  = var.spoke_config.tenant_id
    environment                = var.spoke_config.environment
    key_vault_id               = var.spoke_config.key_vault_id
    key_vault_name             = var.spoke_config.key_vault_name
    storage_account_id         = var.spoke_config.storage_account_id
    storage_account_name       = var.spoke_config.storage_account_name
    virtual_network_id         = var.spoke_config.virtual_network_id
    virtual_network_name       = var.spoke_config.virtual_network_name
    tags                       = var.spoke_config.tags
    log_analytics_workspace_id = var.spoke_config.log_analytics_workspace_id
    log_analytics_workspace_name = var.spoke_config.log_analytics_workspace_name
  }
}