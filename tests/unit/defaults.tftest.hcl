mock_provider "azapi" {
  # The AVM interfaces utility module looks role definitions up by display name. Provide an empty
  # result set so the lookup falls through to the supplied `role_definition_id_or_name` value.
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = []
      }
    }
  }
}

mock_provider "modtm" {}

mock_provider "random" {}

variables {
  location   = "Global"
  name       = "ag-avm-unit"
  parent_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit"
  short_name = "avmunit"
}

run "defaults" {
  command = apply

  variables {
    email_receivers = {
      on_call = {
        name          = "on-call"
        email_address = "on-call@contoso.com"
      }
    }
  }

  assert {
    condition     = output.resource_id != null
    error_message = "The module must return the action group resource ID."
  }
  assert {
    condition     = output.name == "ag-avm-unit"
    error_message = "The module must return the configured action group name."
  }
  assert {
    condition     = azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit"
    error_message = "The action group must be created under the configured parent resource ID."
  }
  assert {
    condition     = azapi_resource.this.type == "Microsoft.Insights/actionGroups@2023-01-01"
    error_message = "The default resource type must be the latest stable action group API version."
  }
  assert {
    condition     = azapi_resource.this.location == "Global"
    error_message = "The action group must be created in the supplied location."
  }
  assert {
    condition     = azapi_resource.this.body.properties.groupShortName == "avmunit"
    error_message = "The short name must be mapped to `groupShortName`."
  }
  assert {
    condition     = azapi_resource.this.body.properties.enabled == true
    error_message = "The action group must be enabled by default."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.emailReceivers) == 1
    error_message = "A single email receiver must be sent to Azure."
  }
  assert {
    condition     = azapi_resource.this.body.properties.emailReceivers[0].name == "on-call"
    error_message = "The Azure visible receiver name must come from `name`, not from the map key."
  }
  assert {
    condition     = azapi_resource.this.body.properties.emailReceivers[0].emailAddress == "on-call@contoso.com"
    error_message = "The email address must be mapped to `emailAddress`."
  }
  assert {
    condition     = azapi_resource.this.body.properties.emailReceivers[0].useCommonAlertSchema == false
    error_message = "The common alert schema must default to disabled, matching the Azure default."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.webhookReceivers) == 0
    error_message = "Receiver collections that were not configured must be sent as empty arrays."
  }
  assert {
    condition     = azapi_resource.this.retry == null
    error_message = "`retry` must default to null on the primary resource."
  }
  assert {
    condition     = length(azapi_resource.lock) == 0
    error_message = "No lock must be created when `lock` is null."
  }
  assert {
    condition     = length(azapi_resource.role_assignments) == 0
    error_message = "No role assignments must be created when `role_assignments` is empty."
  }
}

run "disabled_action_group_with_tags" {
  command = apply

  variables {
    enabled = false
    email_receivers = {
      on_call = {
        name          = "on-call"
        email_address = "on-call@contoso.com"
      }
    }
    tags = {
      environment = "test"
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.enabled == false
    error_message = "The action group must be disabled when `enabled` is false."
  }
  assert {
    condition     = azapi_resource.this.tags["environment"] == "test"
    error_message = "Tags must be propagated to the action group."
  }
}

run "telemetry_enabled" {
  command = apply

  variables {
    enable_telemetry = true
    email_receivers = {
      on_call = {
        name          = "on-call"
        email_address = "on-call@contoso.com"
      }
    }
  }

  assert {
    condition     = length(modtm_telemetry.telemetry) == 1
    error_message = "Telemetry must be emitted when `enable_telemetry` is true."
  }
}

run "telemetry_disabled" {
  command = apply

  variables {
    enable_telemetry = false
    email_receivers = {
      on_call = {
        name          = "on-call"
        email_address = "on-call@contoso.com"
      }
    }
  }

  assert {
    condition     = length(modtm_telemetry.telemetry) == 0
    error_message = "No telemetry must be emitted when `enable_telemetry` is false."
  }
  assert {
    condition     = length(random_uuid.telemetry) == 0
    error_message = "No telemetry identifier must be generated when `enable_telemetry` is false."
  }
}
