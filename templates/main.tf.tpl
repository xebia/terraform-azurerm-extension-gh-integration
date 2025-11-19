# Terraform Configuration for ${project_name} Integration

# Data source for current Azure client configuration
data "azurerm_client_config" "this" {}

# Use the integration resources module to create additional resources
module "integration_resources" {
  source = "git::https://xebia-partner-dr.ghe.com/xms-landingzone-demo/terraform-azurerm-integration-resources.git?ref=feature/refactor-function-apps"

  # Required variables from spoke deployment outputs
  spoke_name                = var.spoke_name
  spoke_resource_group_name = var.spoke_resource_group_name
  spoke_location           = var.spoke_location
  spoke_tags               = var.spoke_tags
  tenant_id                = data.azurerm_client_config.this.tenant_id
  environment              = var.environment
  integration_purpose      = var.integration_purpose

  # Network configuration - dual subnet approach for private spoke deployment
  spoke_pe_subnet_id = length(var.subnet_ids) > 0 ? lookup(var.subnet_ids, "${var.spoke_name}-pe", lookup(var.subnet_ids, "snet-${var.spoke_name}-pe", "")) : ""
  spoke_integration_subnet_id = length(var.subnet_ids) > 0 ? lookup(var.subnet_ids, "${var.spoke_name}-integration", lookup(var.subnet_ids, "snet-${var.spoke_name}-integration", "")) : ""

  # Enhanced networking support - pass all VNets and subnets for advanced configurations
  spoke_virtual_networks   = var.spoke_virtual_networks
  spoke_subnets           = var.spoke_subnets
}