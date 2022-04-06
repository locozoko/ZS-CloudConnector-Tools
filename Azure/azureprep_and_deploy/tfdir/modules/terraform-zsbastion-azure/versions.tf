terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.45.1"
    }
  }
  required_version = ">= 0.13"
}

provider "azurerm" {
  features {}
}