# Terraform Configuration for ${project_name} Integration

# Use the integration resources module to create additional resources
module "integration_resources" {
  source = "git::https://xebia-partner-dr.ghe.com/xms-landingzone-demo/terraform-azurerm-integration-resources.git?ref=main"

  # Pass spoke outputs as inputs to the integration resources module
  spoke_name                = var.spoke_name
  spoke_resource_group_name = var.spoke_resource_group_name
  spoke_location           = var.spoke_location
  spoke_tags               = var.spoke_tags
  tenant_id                = var.tenant_id
  environment              = var.environment
  integration_purpose      = var.integration_purpose

  # Enhanced networking support - pass all VNets and subnets
  spoke_virtual_networks   = var.spoke_virtual_networks
  spoke_subnets           = var.spoke_subnets
}

# Example: How to access specific subnets by name or type
locals {
  # Find a specific subnet by name (example: "snet-web")
  web_subnet = try([
    for subnet in var.spoke_subnets : subnet.subnet_id 
    if contains(split("-", subnet.subnet_name), "web")
  ][0], "")
  
  # Find subnets for a specific VNet
  primary_vnet_subnets = try([
    for subnet in var.spoke_subnets : subnet
    if subnet.vnet_key == keys(var.spoke_virtual_networks)[0]
  ], [])
  
  # Get all subnet IDs as a list
  all_subnet_ids = [for subnet in var.spoke_subnets : subnet.subnet_id]
  
  # Get the first available subnet ID (for simple scenarios)
  primary_subnet_id = length(local.all_subnet_ids) > 0 ? local.all_subnet_ids[0] : ""
}

# Example: Create a private endpoint in each available subnet
resource "azurerm_resource_group" "example" {
  count    = length(var.spoke_subnets) > 0 ? 1 : 0
  name     = "${var.spoke_name}-integration-example"
  location = var.spoke_location
  tags     = var.spoke_tags
}

# Uncomment below to create example private endpoints
/*
resource "azurerm_private_endpoint" "example" {
  for_each = { for subnet in var.spoke_subnets : subnet.subnet_key => subnet }
  
  name                = "${var.spoke_name}-pe-${each.key}"
  location            = var.spoke_location
  resource_group_name = azurerm_resource_group.example[0].name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "psc-${each.key}"
    private_connection_resource_id = "/subscriptions/example/resourceGroups/example/providers/Microsoft.Storage/storageAccounts/example"
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = var.spoke_tags
}
*/