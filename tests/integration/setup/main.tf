terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "The Azure region used for the supporting resource group."
  nullable    = false
}

data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location  = var.location
  name      = "rg-avm-ag-int-${random_string.suffix.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"

  response_export_values = []
}

output "resource_group_id" {
  description = "The resource ID of the transient resource group used by the integration tests."
  value       = azapi_resource.resource_group.id
}

output "subscription_id" {
  description = "The subscription the integration tests are running against."
  value       = data.azapi_client_config.current.subscription_id
}

output "suffix" {
  description = "A random suffix used to build unique resource names."
  value       = random_string.suffix.result
}
