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

# Example: Create a resource group for integration resources
resource "azurerm_resource_group" "integration" {
  count    = length(var.spoke_subnets) > 0 ? 1 : 0
  name     = local.naming.resource_group_name
  location = local.spoke_info.location
  tags     = local.integration_tags
}

# Example: Create a storage account using the primary subnet for private endpoint
resource "azurerm_storage_account" "integration" {
  count = length(local.subnet_lookup.pe_subnets) > 0 ? 1 : 0
  
  name                     = local.naming.storage_account_name
  resource_group_name      = azurerm_resource_group.integration[0].name
  location                = local.spoke_info.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Disable public access when we have private endpoints
  public_network_access_enabled = false
  
  tags = local.integration_tags
}

# Example: Create private endpoint for storage account
resource "azurerm_private_endpoint" "storage_pe" {
  count = length(local.subnet_lookup.pe_subnets) > 0 && length(azurerm_storage_account.integration) > 0 ? 1 : 0
  
  name                = "$${local.naming.prefix}-storage-pe"
  location            = local.spoke_info.location
  resource_group_name = azurerm_resource_group.integration[0].name
  subnet_id           = local.subnet_lookup.pe_subnets[0].subnet_id

  private_service_connection {
    name                           = "$${local.naming.prefix}-storage-psc"
    private_connection_resource_id = azurerm_storage_account.integration[0].id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = local.integration_tags
}

# Example: Create additional resources for each VNet
resource "azurerm_network_security_group" "integration_nsg" {
  for_each = local.vnet_lookup.vnet_to_subnets
  
  name                = "$${local.naming.prefix}-$${each.key}-nsg"
  location            = local.spoke_info.location
  resource_group_name = azurerm_resource_group.integration[0].name

  # Example security rule
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.integration_tags
}