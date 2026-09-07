# Versions are pinned on purpose. An agent asked for "the latest provider" writes
# a configuration that changes under you between two runs.
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
