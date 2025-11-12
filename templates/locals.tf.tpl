# Local values for ${project_name} Integration
# These locals provide convenient access to spoke data and common patterns

locals {
  # Basic spoke information
  spoke_info = {
    name              = var.spoke_name
    resource_group    = var.spoke_resource_group_name
    location          = var.spoke_location
    environment       = var.environment
    tenant_id         = var.tenant_id
    integration_purpose = var.integration_purpose
  }

  # Enhanced spoke tags with integration context
  integration_tags = merge(
    var.spoke_tags,
    {
      "ManagedBy"     = "Terraform"
      "IntegratedBy"  = "${project_name}"
      "Source"        = "spoke-integration"
    }
  )

  # Networking convenience mappings
  networking = {
    # Get all VNets as a simple list
    vnet_names = keys(var.spoke_virtual_networks)
    vnet_ids   = [for vnet in var.spoke_virtual_networks : vnet.id]
    
    # Get all subnets as simple lists
    subnet_names = [for subnet in var.spoke_subnets : subnet.subnet_name]
    subnet_ids   = [for subnet in var.spoke_subnets : subnet.subnet_id]
    
    # Primary VNet (first one found)
    primary_vnet_key  = length(local.networking.vnet_names) > 0 ? local.networking.vnet_names[0] : ""
    primary_vnet_id   = length(local.networking.vnet_ids) > 0 ? local.networking.vnet_ids[0] : ""
    primary_vnet_name = length(local.networking.vnet_names) > 0 ? var.spoke_virtual_networks[local.networking.primary_vnet_key].name : ""
    
    # Primary subnet (first one found)
    primary_subnet_id   = length(local.networking.subnet_ids) > 0 ? local.networking.subnet_ids[0] : ""
    primary_subnet_name = length(var.spoke_subnets) > 0 ? var.spoke_subnets[0].subnet_name : ""
  }

  # Subnet lookup helpers
  subnet_lookup = {
    # Find subnets by type/purpose (based on naming convention)
    pe_subnets = [
      for subnet in var.spoke_subnets : subnet
      if can(regex(".*-pe(-.*)?$", subnet.subnet_name))
    ]
    
    web_subnets = [
      for subnet in var.spoke_subnets : subnet
      if can(regex(".*-web(-.*)?$", subnet.subnet_name))
    ]
    
    app_subnets = [
      for subnet in var.spoke_subnets : subnet
      if can(regex(".*-app(-.*)?$", subnet.subnet_name))
    ]
    
    data_subnets = [
      for subnet in var.spoke_subnets : subnet
      if can(regex(".*-data(-.*)?$", subnet.subnet_name))
    ]
  }

  # VNet lookup helpers
  vnet_lookup = {
    # Map VNet keys to their subnets
    vnet_to_subnets = {
      for vnet_key, vnet in var.spoke_virtual_networks : vnet_key => [
        for subnet in var.spoke_subnets : subnet
        if subnet.vnet_key == vnet_key
      ]
    }
  }

  # Common naming patterns
  naming = {
    prefix = "$${var.spoke_name}-integration"
    
    # Generate standard resource names
    resource_group_name = "$${local.naming.prefix}-rg"
    storage_account_name = replace("$${local.naming.prefix}sa", "-", "")
    key_vault_name = "$${local.naming.prefix}-kv"
    
    # Generate names with suffixes
    names_with_suffix = {
      rg  = "$${local.naming.prefix}-rg"
      sa  = replace("$${local.naming.prefix}sa", "-", "")
      kv  = "$${local.naming.prefix}-kv"
      law = "$${local.naming.prefix}-law"
      appi = "$${local.naming.prefix}-appi"
    }
  }
}