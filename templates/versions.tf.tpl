terraform {
  backend "azurerm" {
    # Backend configuration will be provided during init
    # via command line parameters or environment variables
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  required_version = ">= 1.0"
}