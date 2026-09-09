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

# An aliased provider is declared to prove that the module carries no provider configuration of
# its own and can be driven by any AzAPI provider instance the consumer chooses.
provider "azapi" {
  alias = "alternate"
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
  location               = var.location
  name                   = "rg-avm-ag-complete-${random_string.suffix.result}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2021-04-01"
  response_export_values = []
}

module "action_group" {
  source = "../../"
  providers = {
    azapi = azapi.alternate
  }

  location   = "Global"
  name       = "ag-avm-complete-${random_string.suffix.result}"
  parent_id  = azapi_resource.resource_group.id
  short_name = "avmcomplete"
  arm_role_receivers = {
    # `Monitoring Reader` built-in role definition GUID.
    monitoring_reader = {
      name                    = "monitoring-reader"
      role_id                 = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
      use_common_alert_schema = true
    }
  }
  azure_app_push_receivers = {
    mobile_app = {
      name          = "mobile-app"
      email_address = "avm-example-mobile@contoso.com"
    }
  }
  email_receivers = {
    # Common alert schema enabled.
    on_call = {
      name                    = "on-call"
      email_address           = "avm-example-on-call@contoso.com"
      use_common_alert_schema = true
    }
    # Common alert schema disabled, which is the Azure default.
    service_owner = {
      name          = "service-owner"
      email_address = "avm-example-owner@contoso.com"
    }
  }
  enable_telemetry = var.enable_telemetry
  enabled          = true
  # Suppress drift on the action group's tags, which are frequently rewritten by Azure Policy.
  ignore_body_changes = {
    insights_action_groups = ["tags"]
  }
  lock = {
    kind  = "CanNotDelete"
    notes = "Protected by the AVM complete example."
  }
  retry = {
    error_message_regex  = ["ResourceGroupNotFound"]
    interval_seconds     = 10
    max_interval_seconds = 60
  }
  role_assignments = {
    monitoring_reader = {
      role_definition_id_or_name = "Monitoring Reader"
      principal_id               = data.azapi_client_config.current.object_id
    }
  }
  sms_receivers = {
    on_call = {
      name         = "on-call-sms"
      country_code = "44"
      phone_number = "1234567890"
    }
  }
  tags = {
    environment = "avm-example"
    scenario    = "complete"
  }
  timeouts = {
    create = "10m"
    delete = "10m"
    read   = "5m"
    update = "10m"
  }
  voice_receivers = {
    escalation = {
      name         = "escalation-voice"
      country_code = "44"
      phone_number = "1234567891"
    }
  }
  webhook_receivers = {
    ops_bridge = {
      name                    = "ops-bridge"
      service_uri             = "https://example.com/azure-monitor/ops-bridge"
      use_common_alert_schema = true
    }
  }
}
