# Terraform Configuration for ${project_name} Integration

# Data source for current Azure client configuration
data "azurerm_client_config" "this" {}

# Use the integration resources module to create additional resources
module "integration_resources" {
  source = "git::https://xebia-partner-dr.ghe.com/xms-landingzone-demo/terraform-azurerm-integration-resources.git?ref=feature/refactor-function-apps"

  # Required variables from spoke deployment outputs
  spoke_name                = "${spoke_name}"
  spoke_resource_group_name = "${spoke_resource_group_name}"
  spoke_location           = "${spoke_location}"
  spoke_tags               = ${jsonencode(spoke_tags)}
  tenant_id                = data.azurerm_client_config.this.tenant_id
  environment              = "${environment}"
  integration_purpose      = "${integration_purpose}"

  # Use spoke storage account and key vault (reduces resource duplication)
  spoke_storage_account_name = "${storage_account_name}"
  spoke_key_vault_id        = "${key_vault_id}"  
  spoke_key_vault_name      = "${key_vault_name}"

  # Network configuration - dual subnet approach for private spoke deployment
  spoke_pe_subnet_id = length(${jsonencode(subnet_ids)}) > 0 ? lookup(${jsonencode(subnet_ids)}, "${spoke_name}-pe", lookup(${jsonencode(subnet_ids)}, "snet-${spoke_name}-pe", "")) : ""
  spoke_integration_subnet_id = length(${jsonencode(subnet_ids)}) > 0 ? lookup(${jsonencode(subnet_ids)}, "${spoke_name}-integration", lookup(${jsonencode(subnet_ids)}, "snet-${spoke_name}-integration", "")) : ""

  # Enhanced networking support - pass all VNets and subnets for advanced configurations
  spoke_virtual_networks   = ${jsonencode(spoke_virtual_networks)}
  spoke_subnets           = ${jsonencode(spoke_subnets)}
}