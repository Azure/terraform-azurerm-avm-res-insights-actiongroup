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
  name                   = "rg-avm-ag-waf-${random_string.suffix.result}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2021-04-01"
  response_export_values = []
  tags = {
    environment = "avm-example"
    scenario    = "waf-aligned"
  }
}

module "action_group" {
  source = "../../"

  location   = "Global"
  name       = "ag-avm-waf-${random_string.suffix.result}"
  parent_id  = azapi_resource.resource_group.id
  short_name = "avmwaf"
  azure_app_push_receivers = {
    on_call = {
      name          = "on-call-mobile"
      email_address = "avm-example-on-call@contoso.com"
    }
  }
  email_receivers = {
    on_call = {
      name                    = "on-call"
      email_address           = "avm-example-on-call@contoso.com"
      use_common_alert_schema = true
    }
    service_owner = {
      name                    = "service-owner"
      email_address           = "avm-example-owner@contoso.com"
      use_common_alert_schema = true
    }
  }
  enable_telemetry = var.enable_telemetry
  enabled          = true
  lock = {
    kind  = "CanNotDelete"
    notes = "Protect the alert notification path from accidental deletion."
  }
  tags = {
    environment = "avm-example"
    scenario    = "waf-aligned"
  }
}
