# Outputs for ${project_name} Integration

# Basic integration information
output "integration_info" {
  description = "Basic information about the integration deployment"
  value = {
    spoke_name    = var.spoke_name
    environment   = var.environment
    location      = var.spoke_location
  }
}

# Function App outputs (if any function apps are deployed)
output "function_apps" {
  description = "Function App deployment information"
  value = module.integration_resources.function_apps
  sensitive = false
}

# Service Plan outputs
output "service_plans" {
  description = "App Service Plan deployment information"  
  value = module.integration_resources.service_plans
  sensitive = false
}

# Network configuration outputs
output "network_config" {
  description = "Network configuration used for integration"
  value = {
    pe_subnet_configured = length(var.subnet_ids) > 0 && lookup(var.subnet_ids, "${var.spoke_name}-pe", lookup(var.subnet_ids, "snet-${var.spoke_name}-pe", "")) != ""
    integration_subnet_configured = length(var.subnet_ids) > 0 && lookup(var.subnet_ids, "${var.spoke_name}-integration", lookup(var.subnet_ids, "snet-${var.spoke_name}-integration", "")) != ""
    virtual_network_id = var.virtual_network_id
    virtual_network_name = var.virtual_network_name
  }
  sensitive = false
}

# Key Vault outputs
output "key_vault_info" {
  description = "Key Vault configuration from spoke"
  value = {
    spoke_key_vault_id = var.key_vault_id
    spoke_key_vault_name = var.key_vault_name
    integration_key_vault_id = module.integration_resources.key_vault_id
    integration_key_vault_uri = module.integration_resources.key_vault_uri
  }
  sensitive = false
}

# Storage outputs
output "storage_info" {
  description = "Storage account information"
  value = {
    storage_account_name = module.integration_resources.storage_account_name
    storage_account_id = module.integration_resources.storage_account_id
  }
  sensitive = false
}