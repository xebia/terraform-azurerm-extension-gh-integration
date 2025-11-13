# Spoke outputs auto-generated from ${spoke_name} spoke deployment
# This file is automatically updated when spoke configuration changes
# Do not modify manually - changes will be overwritten

# Core spoke information
spoke_name                    = "${spoke_name}"
subscription_id              = "${subscription_id}"
spoke_resource_group_name    = "${spoke_resource_group_name}"
spoke_location               = "${spoke_location}"

# Key Vault configuration
key_vault_id                 = "${key_vault_id}"
key_vault_name               = "${key_vault_name}"

# Virtual Network configuration  
virtual_network_id           = "${virtual_network_id}"
virtual_network_name         = "${virtual_network_name}"

# All subnet configurations
# Choose the appropriate subnet for your integration in main.tf
%{ if length(subnet_ids) > 0 ~}
subnet_ids = {
%{ for name, id in subnet_ids ~}
  "${name}" = "${id}"
%{ endfor ~}
}

subnet_names = {
%{ for key, name in subnet_names ~}
  "${key}" = "${name}"
%{ endfor ~}
}
%{ else ~}
# No subnets available from spoke deployment
subnet_ids   = {}
subnet_names = {}
%{ endif ~}

# Log Analytics workspace configuration
%{ if log_analytics_workspace_id != "" ~}
log_analytics_workspace_id  = "${log_analytics_workspace_id}"
%{ else ~}
log_analytics_workspace_id  = ""
%{ endif ~}

# Application Insights configuration  
%{ if application_insights_id != "" ~}
application_insights_id      = "${application_insights_id}"
%{ else ~}
application_insights_id      = ""
%{ endif ~}