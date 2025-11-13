# Variables for Integration Module

# Repository Configuration
variable "repository_name" {
  description = "Name of the integration repository"
  type        = string
}

variable "repository_description" {
  description = "Description of the integration repository"
  type        = string
  default     = ""
}

# Spoke Configuration
variable "spoke_name" {
  description = "Name of the spoke deployment"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "spoke_resource_group_name" {
  description = "Spoke resource group name"
  type        = string
}

variable "spoke_location" {
  description = "Spoke location"
  type        = string
}

# Key Vault Configuration
variable "key_vault_id" {
  description = "Key Vault resource ID"
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault name"
  type        = string
}

# Virtual Network Configuration
variable "virtual_network_id" {
  description = "Virtual network resource ID"
  type        = string
}

variable "virtual_network_name" {
  description = "Virtual network name"
  type        = string
}

# Subnet Configuration - ALL subnets from spoke (user chooses in main.tf)
variable "subnet_ids" {
  description = "Map of all subnet IDs from spoke deployment"
  type        = map(string)
  default     = {}
}

variable "subnet_names" {
  description = "Map of all subnet names from spoke deployment"
  type        = map(string)
  default     = {}
}

# Optional Components
variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID"
  type        = string
  default     = ""
}

variable "application_insights_id" {
  description = "Application Insights resource ID"
  type        = string
  default     = ""
}

# Legacy support for project_name (use repository_name instead)
variable "project_name" {
  description = "Name of the integration project (deprecated - use repository_name instead)"
  type        = string
  default     = ""
}