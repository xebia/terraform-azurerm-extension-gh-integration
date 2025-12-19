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

variable "project_name" {
  description = "Name of the integration project"
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

variable "environment" {
  description = "Environment name (dev, test, prod)"
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

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace resource name"
  type        = string
  default     = ""
}

# Terraform State Backend Configuration
variable "terraform_state_resource_group" {
  description = "Resource group containing Terraform state storage account"
  type        = string
  default     = ""
}

variable "terraform_state_storage_account" {
  description = "Storage account name for Terraform state"
  type        = string
  default     = ""
}

variable "terraform_state_container" {
  description = "Container name for Terraform state"
  type        = string
  default     = ""
}

variable "github_repository_name" {
  description = "Name of the GitHub repository to use for integration files and secrets."
  type        = string
}

variable "spoke_config" {
  description = "Dummy object for template rendering"
  type = object({
    name                 = string
    resource_group_name  = string
    location             = string
    tenant_id            = string
    environment          = string
    storage_account_name = string
    key_vault_id         = string
    key_vault_name       = string
    pe_subnet_id         = string
  })
  default = {
    name                 = "dummy"
    resource_group_name  = "dummy"
    location             = "dummy"
    tenant_id            = "dummy"
    environment          = "dummy"
    storage_account_name = "dummy"
    key_vault_id         = "dummy"
    key_vault_name       = "dummy"
    pe_subnet_id         = "dummy"
  }
}

variable "integration_module_source" {
  description = "Source of the integration module"
  type        = string
  default     = "git::https://github.com/xebia/xms-integration-modules.git?ref=main"
}