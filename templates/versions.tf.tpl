terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    msgraph = {
      source  = "microsoft/msgraph"
      version = "~> 0.2"
    }
  }
  
  required_version = ">= 1.9, < 2.0"
}