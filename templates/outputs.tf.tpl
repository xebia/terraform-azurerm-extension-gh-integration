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
output "function_app_info" {
  description = "Function App deployment information"
  value = module.integration_resources.function_app_info
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
    key_vault_id = var.key_vault_id
    key_vault_name = var.key_vault_name
  }
  sensitive = false
}