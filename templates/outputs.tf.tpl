# Outputs for ${project_name} Integration

output "integration_resources" {
  description = "Integration resources created by the module"
  value = {
    storage_account_name = module.integration_resources.storage_account_name
    storage_account_id   = module.integration_resources.storage_account_id
    key_vault_id         = module.integration_resources.key_vault_id
    key_vault_uri        = module.integration_resources.key_vault_uri
  }
}

# Networking information outputs
output "spoke_networking_info" {
  description = "Complete networking information from spoke deployment"
  value = {
    virtual_networks     = ${spoke_virtual_networks}
    all_subnets         = ${spoke_subnets}
    subnet_count        = length(${spoke_subnets})
    vnet_count          = length(${spoke_virtual_networks})
    primary_subnet_id   = length(${spoke_subnets}) > 0 ? ${spoke_subnets}[0].subnet_id : ""
  }
}

# Helper outputs for common subnet access patterns
output "subnet_ids_by_name" {
  description = "Map of subnet names to their IDs"
  value = {
    for subnet in ${spoke_subnets} : subnet.subnet_name => subnet.subnet_id
  }
}

output "subnets_by_vnet" {
  description = "Subnets grouped by virtual network"
  value = {
    for vnet_key, vnet in ${spoke_virtual_networks} : vnet_key => {
      vnet_name = vnet.name
      subnets   = [
        for subnet in ${spoke_subnets} : subnet
        if subnet.vnet_key == vnet_key
      ]
    }
  }
}