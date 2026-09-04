variables {
  location = "Global"
}

run "setup" {
  module {
    source = "./tests/integration/setup"
  }

  variables {
    location = "westeurope"
  }
}

run "create" {
  variables {
    name       = "ag-avm-int-${run.setup.suffix}"
    parent_id  = run.setup.resource_group_id
    short_name = "avmint"
    email_receivers = {
      on_call = {
        name                    = "on-call"
        email_address           = "avm-integration-test@contoso.com"
        use_common_alert_schema = true
      }
    }
    tags = {
      environment = "avm-integration-test"
    }
  }

  assert {
    condition     = output.resource_id != null
    error_message = "Azure must return a resource ID for the created action group."
  }
  assert {
    condition     = output.name == "ag-avm-int-${run.setup.suffix}"
    error_message = "Azure must return the requested action group name."
  }
  assert {
    condition     = output.parent_id == run.setup.resource_group_id
    error_message = "The action group must be created in the requested resource group."
  }
}

run "update_receivers_and_disable" {
  variables {
    enabled    = false
    name       = "ag-avm-int-${run.setup.suffix}"
    parent_id  = run.setup.resource_group_id
    short_name = "avmint2"
    email_receivers = {
      on_call = {
        name                    = "on-call"
        email_address           = "avm-integration-test@contoso.com"
        use_common_alert_schema = true
      }
      owner = {
        name          = "owner"
        email_address = "avm-integration-owner@contoso.com"
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
      environment = "avm-integration-test"
      updated     = "true"
    }
    webhook_receivers = {
      ops = {
        name                    = "ops"
        service_uri             = "https://example.com/azure-monitor/ops"
        use_common_alert_schema = true
      }
    }
  }

  assert {
    condition     = output.resource_id == run.create.resource_id
    error_message = "Adding receivers and disabling the action group must update it in place, not replace it."
  }
  assert {
    condition     = azapi_resource.this.body.properties.enabled == false
    error_message = "The action group must be disabled after the update."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.emailReceivers) == 2
    error_message = "Both email receivers must be present after the update."
  }
}

run "remove_receivers_and_reenable" {
  variables {
    enabled    = true
    name       = "ag-avm-int-${run.setup.suffix}"
    parent_id  = run.setup.resource_group_id
    short_name = "avmint2"
    email_receivers = {
      on_call = {
        name                    = "on-call"
        email_address           = "avm-integration-test@contoso.com"
        use_common_alert_schema = true
      }
    }
    tags = {
      environment = "avm-integration-test"
    }
  }

  assert {
    condition     = output.resource_id == run.create.resource_id
    error_message = "Removing receivers must update the action group in place, not replace it."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.emailReceivers) == 1
    error_message = "Only the retained email receiver must remain."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.smsReceivers) == 0
    error_message = "The removed SMS receiver must no longer be configured."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.webhookReceivers) == 0
    error_message = "The removed webhook receiver must no longer be configured."
  }
}

run "idempotency" {
  command = plan

  variables {
    enabled    = true
    name       = "ag-avm-int-${run.setup.suffix}"
    parent_id  = run.setup.resource_group_id
    short_name = "avmint2"
    email_receivers = {
      on_call = {
        name                    = "on-call"
        email_address           = "avm-integration-test@contoso.com"
        use_common_alert_schema = true
      }
    }
    tags = {
      environment = "avm-integration-test"
    }
  }

  assert {
    condition     = azapi_resource.this.id == run.create.resource_id
    error_message = "Re-planning an unchanged configuration must not propose replacing the action group."
  }
}
