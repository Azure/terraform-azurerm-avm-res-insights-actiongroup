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

provider "azapi" {}

data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location               = var.location
  name                   = "rg-avm-ag-default-${random_string.suffix.result}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2021-04-01"
  response_export_values = []
}

# This is the module call.
# Azure Monitor action groups are global resources, so `location` is `Global`.
module "action_group" {
  source = "../../"

  location   = "Global"
  name       = "ag-avm-default-${random_string.suffix.result}"
  parent_id  = azapi_resource.resource_group.id
  short_name = "avmdefault"
  email_receivers = {
    on_call = {
      name          = "on-call"
      email_address = "avm-example-on-call@contoso.com"
    }
  }
  enable_telemetry = var.enable_telemetry
}
