# Variables for ${project_name} Integration
# These variables are populated from spoke-outputs.tfvars

variable "spoke_config" {
  description = "Consolidated spoke configuration object from spoke-outputs.tfvars"
  type = object({
    name                 = string
    subscription_id      = string
    resource_group_name  = string
    location             = string
    tenant_id            = string
    environment          = string
    key_vault_id         = string
    key_vault_name       = string
    storage_account_id   = string
    storage_account_name = string
    virtual_network_id   = string
    virtual_network_name = string
    tags                 = optional(map(string), {})
    subnet_ids           = map(string)
    subnet_names         = map(string)
    log_analytics_workspace_id  = string
    log_analytics_workspace_name = string
  })
}