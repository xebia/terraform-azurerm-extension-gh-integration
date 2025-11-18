# Variables for Integration Module

# Repository Configuration
variable "repository_name" {
  description = "Name of the integration repository"
  type        = string
  default     = ""
}

variable "repository_description" {
  description = "Description of the integration repository"
  type        = string
  default     = ""
}

# Project name (legacy compatibility)
variable "project_name" {
  description = "Name of the integration project (legacy)"
  type        = string
  default     = ""
}

# Spoke Configuration
variable "spoke_name" {
  description = "Name of the spoke deployment"
  type        = string
  default     = ""
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
}

variable "spoke_resource_group_name" {
  description = "Spoke resource group name"
  type        = string
  default     = ""
}

variable "spoke_location" {
  description = "Spoke location"
  type        = string
  default     = ""
}

# Key Vault Configuration
variable "key_vault_id" {
  description = "Key Vault resource ID"
  type        = string
  default     = ""
}

variable "key_vault_name" {
  description = "Key Vault name"
  type        = string
  default     = ""
}

# Virtual Network Configuration
variable "virtual_network_id" {
  description = "Virtual network resource ID"
  type        = string
  default     = ""
}

variable "virtual_network_name" {
  description = "Virtual network name"
  type        = string
  default     = ""
}

# Legacy spoke deployment compatibility variables
variable "github_organization" {
  description = "GitHub organization name (legacy)"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub token (legacy)"
  type        = string
  default     = ""
}

variable "azure_tenant_id" {
  description = "Azure tenant ID (legacy)"
  type        = string
  default     = ""
}

variable "azure_subscription_id" {
  description = "Azure subscription ID (legacy)"
  type        = string
  default     = ""
}

variable "service_principal_client_id" {
  description = "Service principal client ID (legacy)"
  type        = string
  default     = ""
}

variable "github_oidc_issuer" {
  description = "GitHub OIDC issuer (legacy)"
  type        = string
  default     = ""
}

variable "spoke_outputs" {
  description = "Spoke outputs (legacy)"
  type        = any
  default     = {}
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