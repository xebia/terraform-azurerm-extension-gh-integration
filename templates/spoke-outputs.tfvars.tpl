## Spoke outputs auto-generated from ${spoke_name} spoke deployment
# This file is automatically updated when spoke configuration changes
# Do not modify manually - changes will be overwritten

spoke_config = {
  name                 = "${spoke_name}"
  subscription_id      = "${subscription_id}"
  resource_group_name  = "${spoke_resource_group_name}"
  location             = "${spoke_location}"
  tenant_id            = "${tenant_id}"
  environment          = "${environment}"
  key_vault_id         = "${key_vault_id}"
  key_vault_name       = "${key_vault_name}"
  storage_account_id   = "${storage_account_id}"
  storage_account_name = "${storage_account_name}"
  virtual_network_id   = "${virtual_network_id}"
  virtual_network_name = "${virtual_network_name}"
  # Subnet info (choose appropriate subnet in main.tf)
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
  log_analytics_workspace_id  = "${log_analytics_workspace_id}"
  log_analytics_workspace_name  = "${log_analytics_workspace_name}"
}