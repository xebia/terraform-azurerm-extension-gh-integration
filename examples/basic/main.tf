terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "github" {
  owner = var.github_organization
  token = var.github_token
}

module "spoke_integration" {
  source = "../../"

  # GitHub configuration
  github_organization = var.github_organization
  github_token        = var.github_token

  # Project configuration
  project_name = var.project_name

  # Spoke outputs
  spoke_outputs = var.spoke_outputs

  # Azure configuration
  azure_subscription_id       = var.azure_subscription_id
  azure_tenant_id            = var.azure_tenant_id
  service_principal_client_id = var.service_principal_client_id
}