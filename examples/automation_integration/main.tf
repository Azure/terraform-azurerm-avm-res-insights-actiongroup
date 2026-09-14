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
  name                   = "rg-avm-ag-automation-${random_string.suffix.result}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2021-04-01"
  response_export_values = []
}

resource "azapi_resource" "automation_account" {
  location  = var.location
  name      = "aa-avm-ag-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Automation/automationAccounts@2023-11-01"
  body = {
    properties = {
      disableLocalAuth    = true
      publicNetworkAccess = false
      sku = {
        name = "Basic"
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "logic_app" {
  location  = var.location
  name      = "logic-avm-ag-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Logic/workflows@2019-05-01"
  body = {
    properties = {
      definition = {
        "$schema"      = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
        actions        = {}
        contentVersion = "1.0.0.0"
        outputs        = {}
        parameters     = {}
        triggers = {
          manual = {
            inputs = {
              schema = {}
            }
            kind = "Http"
            type = "Request"
          }
        }
      }
      state = "Enabled"
    }
  }
  response_export_values = []
}

module "action_group" {
  source = "../../"

  location   = "Global"
  name       = "ag-avm-automation-${random_string.suffix.result}"
  parent_id  = azapi_resource.resource_group.id
  short_name = "avmauto"
  # This receiver is structurally illustrative and is not wired to a working runbook. Azure does
  # not check that `runbook_name`, `webhook_resource_id` or `service_uri` resolve when the action
  # group is created, so the example deploys cleanly, but the receiver would not fire. A real
  # Automation webhook URI embeds a bearer token and is returned only once, at creation time.
  automation_runbook_receivers = {
    remediation = {
      automation_account_id   = azapi_resource.automation_account.id
      name                    = "remediation-runbook"
      runbook_name            = "Restart-Service"
      webhook_resource_id     = "${azapi_resource.automation_account.id}/webhooks/avm-example-webhook"
      is_global_runbook       = false
      service_uri             = "https://example.com/azure-monitor/automation-webhook"
      use_common_alert_schema = true
    }
  }
  enable_telemetry = var.enable_telemetry
  # The Logic App `callback_url` is a synthetic placeholder. A real deployment sources it from a
  # `listCallbackUrl` action, which returns a signed, credential-bearing URL.
  logic_app_receivers = {
    triage = {
      name                    = "triage-workflow"
      resource_id             = azapi_resource.logic_app.id
      callback_url            = "https://example.com/azure-monitor/logic-app-callback"
      use_common_alert_schema = true
    }
  }
  tags = {
    environment = "avm-example"
    scenario    = "automation-integration"
  }
}
