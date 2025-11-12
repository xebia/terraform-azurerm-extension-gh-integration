# Terraform Variables for ${project_name}
spoke_name                  = "${spoke_name}"
spoke_resource_group_name   = "${spoke_resource_group_name}"
spoke_location             = "${spoke_location}"
tenant_id                  = "${tenant_id}"
environment                = "${environment}"
integration_purpose        = "${integration_purpose}"

# Spoke tags
spoke_tags = ${spoke_tags}

# Complete networking information from spoke deployment
spoke_virtual_networks = ${spoke_virtual_networks}

# All subnet information in a simplified format
spoke_subnets = ${spoke_subnets}