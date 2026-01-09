# Terraform Configuration for ${project_name} Integration

# Data source for current Azure client configuration
data "azurerm_client_config" "this" {}

# Use the integration resources module to create additional resources
module "integration_resources" {
  source = "${integration_module_source}"

  # Main spoke prams from the spoke creation output.
  spoke_config = var.spoke_config
}