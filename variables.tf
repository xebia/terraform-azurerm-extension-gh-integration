# Variables for Integration Module

# Azure Configuration
variable "azure_tenant_id" {
  description = "The Azure tenant ID"
  type        = string
}

variable "azure_subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "service_principal_client_id" {
  description = "The client ID of the Azure service principal"
  type        = string
}

# GitHub Configuration
variable "github_organization" {
  description = "The GitHub organization name"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_oidc_issuer" {
  description = "The GitHub OIDC issuer URL"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

# Project Configuration
variable "project_name" {
  description = "Name of the integration project (will be used as repository name)"
  type        = string
}

# Spoke Outputs - All data from the spoke deployment
variable "spoke_outputs" {
  description = "All outputs from the spoke deployment to be passed to integration repository"
  type        = any
  default     = {}
}

# Integration Resource Variables (extracted from spoke_outputs for direct resource creation)
variable "spoke_name" {
  description = "The name of the spoke deployment"
  type        = string
  default     = ""
}

variable "spoke_resource_group_name" {
  description = "The resource group name from the spoke deployment"
  type        = string
  default     = ""
}

variable "spoke_location" {
  description = "The location of the spoke deployment"
  type        = string
  default     = "West Europe"
}

variable "spoke_tags" {
  description = "Tags from the spoke deployment"
  type        = map(string)
  default     = {}
}

variable "spoke_subnet_id" {
  description = "Subnet ID from the spoke deployment for private endpoints"
  type        = string
  default     = ""
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "integration_purpose" {
  description = "Purpose of this integration deployment"
  type        = string
  default     = "Additional resources"
}