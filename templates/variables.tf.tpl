# Variables for ${project_name} Integration
# These variables are populated from spoke-outputs.tfvars

variable "spoke_name" {
  description = "The name of the spoke deployment"
  type        = string
}

variable "spoke_resource_group_name" {
  description = "The resource group name from the spoke deployment"
  type        = string
}

variable "spoke_location" {
  description = "The location of the spoke deployment"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "integration_purpose" {
  description = "Purpose of this integration deployment"
  type        = string
  default     = "Additional resources for spoke integration"
}

variable "spoke_tags" {
  description = "Tags from the spoke deployment"
  type        = map(string)
  default     = {}
}

variable "spoke_virtual_networks" {
  description = "Complete virtual network information from the spoke deployment"
  type = map(object({
    name          = string
    id            = string
    region        = string
    address_space = list(string)
    subnets = map(object({
      name             = string
      id               = string
      address_prefixes = list(string)
    }))
  }))
  default = {}
}

variable "spoke_subnets" {
  description = "All subnet information in simplified format for easy access"
  type = list(object({
    vnet_name        = string
    vnet_key         = string
    subnet_name      = string
    subnet_key       = string
    subnet_id        = string
    address_prefixes = list(string)
  }))
  default = []
}

# Additional variables for enhanced spoke integration
variable "subnet_ids" {
  description = "Map of subnet IDs from spoke deployment"
  type        = map(string)
  default     = {}
}

variable "subnet_names" {
  description = "Map of subnet names from spoke deployment"
  type        = map(string)
  default     = {}
}

variable "virtual_network_id" {
  description = "Virtual network resource ID from spoke deployment"
  type        = string
  default     = ""
}

variable "virtual_network_name" {
  description = "Virtual network name from spoke deployment"
  type        = string
  default     = ""
}

variable "key_vault_id" {
  description = "Key Vault resource ID from spoke deployment"
  type        = string
  default     = ""
}

variable "key_vault_name" {
  description = "Key Vault name from spoke deployment"
  type        = string
  default     = ""
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID from spoke deployment"
  type        = string
  default     = ""
}

variable "application_insights_id" {
  description = "Application Insights resource ID from spoke deployment"
  type        = string
  default     = ""
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}