# Backend configuration for Terraform state
# This uses Azure AD authentication instead of storage account keys
terraform {
  backend "azurerm" {
    # These values will be provided via -backend-config during terraform init
    # resource_group_name  = "rg-name"
    # storage_account_name = "storage-account-name"
    # container_name       = "tfstate"
    # key                  = "integration.tfstate"
    # use_azuread_auth     = true
  }
}