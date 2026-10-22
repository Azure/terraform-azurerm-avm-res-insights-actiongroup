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
  name                   = "rg-avm-ag-secure-${random_string.suffix.result}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2021-04-01"
  response_export_values = []
}

module "action_group" {
  source = "../../"

  location         = "Global"
  name             = "ag-avm-secure-${random_string.suffix.result}"
  parent_id        = azapi_resource.resource_group.id
  short_name       = "avmsecure"
  enable_telemetry = var.enable_telemetry
  tags = {
    environment = "avm-example"
    scenario    = "secure-webhook"
  }
  # A secure webhook receiver. Azure Monitor acquires a Microsoft Entra token for the target
  # application and presents it to the endpoint, so no shared secret is stored anywhere.
  #
  # `object_id` is the object ID of the service principal for the Entra application registration
  # that fronts the receiving endpoint, and `identifier_uri` is that application's Application ID
  # URI. Both values below are synthetic. Replace them with the values from your own tenant.
  webhook_receivers = {
    secure_endpoint = {
      name                    = "secure-endpoint"
      service_uri             = "https://example.com/azure-monitor/secure-webhook"
      identifier_uri          = "api://avm-example-secure-webhook"
      object_id               = "00000000-0000-0000-0000-000000000001"
      tenant_id               = data.azapi_client_config.current.tenant_id
      use_aad_auth            = true
      use_common_alert_schema = true
    }
  }
}
