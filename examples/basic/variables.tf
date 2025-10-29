# Variables for basic example

variable "github_organization" {
  description = "GitHub organization name"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Name of the integration project"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "service_principal_client_id" {
  description = "Azure service principal client ID"
  type        = string
}

variable "spoke_outputs" {
  description = "Outputs from the spoke deployment"
  type        = any
  default     = {}
}