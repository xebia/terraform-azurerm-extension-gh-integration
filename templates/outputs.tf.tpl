# Outputs for ${project_name} Integration

# Basic integration information
output "integration_info" {
  description = "Basic information about the integration deployment"
  value = {
    spoke_name    = var.spoke_name
    environment   = var.environment
    location      = var.spoke_location
    resource_group = try(azurerm_resource_group.integration[0].name, "")
  }
}

# Integration resources created
output "integration_resources" {
  description = "Integration resources created by this deployment"
  value = {
    # Local resources
    resource_group_id = try(azurerm_resource_group.integration[0].id, "")
    storage_account_id = try(azurerm_storage_account.integration[0].id, "")
    private_endpoint_id = try(azurerm_private_endpoint.storage_pe[0].id, "")
    
    # Module resources (if available)
    module_outputs = try(module.integration_resources, {})
  }
  sensitive = true
}

# Spoke networking information (convenient for other resources)
output "spoke_networking_info" {
  description = "Complete networking information from spoke deployment"
  value = {
    virtual_networks     = var.spoke_virtual_networks
    all_subnets         = var.spoke_subnets
    subnet_count        = length(var.spoke_subnets)
    vnet_count          = length(var.spoke_virtual_networks)
    
    # Convenience mappings
    primary_vnet = {
      name = local.networking.primary_vnet_name
      id   = local.networking.primary_vnet_id
    }
    primary_subnet = {
      name = local.networking.primary_subnet_name
      id   = local.networking.primary_subnet_id
    }
    
    # Subnet types
    pe_subnets = local.subnet_lookup.pe_subnets
    web_subnets = local.subnet_lookup.web_subnets
    app_subnets = local.subnet_lookup.app_subnets
    data_subnets = local.subnet_lookup.data_subnets
  }
}

# Helper outputs for common subnet access patterns
output "subnet_ids_by_name" {
  description = "Map of subnet names to their IDs for easy lookup"
  value = {
    for subnet in var.spoke_subnets : subnet.subnet_name => subnet.subnet_id
  }
}

output "subnets_by_vnet" {
  description = "Subnets grouped by virtual network"
  value = {
    for vnet_key, vnet in var.spoke_virtual_networks : vnet_key => {
      vnet_name = vnet.name
      vnet_id   = vnet.id
      subnets   = [
        for subnet in var.spoke_subnets : subnet
        if subnet.vnet_key == vnet_key
      ]
    }
  }
}