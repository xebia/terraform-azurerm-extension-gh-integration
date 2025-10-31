# Terraform Configuration for ${project_name} Integration

# Use the integration resources module to create additional resources
module "integration_resources" {
  source = "git::https://xebia-partner-dr.ghe.com/xms-landingzone-demo/terraform-azurerm-integration-resources.git?ref=main"

  # Pass spoke outputs as inputs to the integration resources module
  spoke_name                = var.spoke_name
  spoke_resource_group_name = var.spoke_resource_group_name
  spoke_location           = var.spoke_location
  spoke_subnet_id          = var.spoke_subnet_id
  spoke_tags               = var.spoke_tags
  tenant_id                = var.tenant_id
  environment              = var.environment
  integration_purpose      = var.integration_purpose
}