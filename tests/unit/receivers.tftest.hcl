mock_provider "azapi" {
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = []
      }
    }
  }
}

mock_provider "azapi" {
  alias = "alternate"

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

run "all_receiver_types" {
  command = apply

  variables {
    arm_role_receivers = {
      monitoring_reader = {
        name                    = "monitoring-reader"
        role_id                 = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
        use_common_alert_schema = true
      }
    }
    automation_runbook_receivers = {
      remediation = {
        automation_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Automation/automationAccounts/aa-avm-unit"
        name                  = "remediation"
        runbook_name          = "Restart-Service"
        webhook_resource_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Automation/automationAccounts/aa-avm-unit/webhooks/wh-avm-unit"
        service_uri           = "https://example.com/automation"
      }
    }
    azure_app_push_receivers = {
      mobile = {
        name          = "mobile"
        email_address = "mobile@contoso.com"
      }
    }
    azure_function_receivers = {
      dispatcher = {
        name                     = "dispatcher"
        function_app_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Web/sites/func-avm-unit"
        function_name            = "DispatchAlert"
        http_trigger_url         = "https://example.com/api/dispatch"
      }
    }
    email_receivers = {
      on_call = {
        name                    = "on-call"
        email_address           = "on-call@contoso.com"
        use_common_alert_schema = true
      }
      owner = {
        name          = "owner"
        email_address = "owner@contoso.com"
      }
    }
    # A namespace in a different subscription to the action group.
    event_hub_receivers = {
      stream = {
        name                = "stream"
        event_hub_namespace = "ehns-avm-unit"
        event_hub_name      = "eh-avm-unit"
        subscription_id     = "11111111-1111-1111-1111-111111111111"
        tenant_id           = "22222222-2222-2222-2222-222222222222"
      }
    }
    itsm_receivers = {
      snow = {
        name                 = "snow"
        workspace_id         = "00000000-0000-0000-0000-000000000000|33333333-3333-3333-3333-333333333333"
        connection_id        = "44444444-4444-4444-4444-444444444444"
        ticket_configuration = "{\"PayloadRevision\":0,\"WorkItemType\":\"Incident\",\"CreateOneWIPerCI\":false}"
        region               = "westcentralus"
      }
    }
    logic_app_receivers = {
      triage = {
        name         = "triage"
        resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Logic/workflows/logic-avm-unit"
        callback_url = "https://example.com/logic-callback"
      }
    }
    sms_receivers = {
      on_call = {
        name         = "on-call-sms"
        country_code = "44"
        phone_number = "1234567890"
      }
    }
    voice_receivers = {
      escalation = {
        name         = "escalation-voice"
        country_code = "1"
        phone_number = "5555550100"
      }
    }
    webhook_receivers = {
      ops = {
        name        = "ops"
        service_uri = "https://example.com/ops"
      }
    }
  }

  assert {
    condition     = length(azapi_resource.this.body.properties.armRoleReceivers) == 1
    error_message = "The ARM role receiver must be sent to Azure."
  }
  assert {
    condition     = azapi_resource.this.body.properties.armRoleReceivers[0].roleId == "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
    error_message = "The ARM role receiver must carry the role definition GUID."
  }
  assert {
    condition     = azapi_resource.this.body.properties.automationRunbookReceivers[0].isGlobalRunbook == false
    error_message = "`is_global_runbook` must default to false."
  }
  assert {
    condition     = azapi_resource.this.body.properties.azureAppPushReceivers[0].emailAddress == "mobile@contoso.com"
    error_message = "The Azure mobile app push receiver must carry the account email address."
  }
  assert {
    condition     = azapi_resource.this.body.properties.azureFunctionReceivers[0].functionName == "DispatchAlert"
    error_message = "The Azure Function receiver must carry the function name."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.emailReceivers) == 2
    error_message = "Both email receivers must be sent to Azure."
  }
  assert {
    condition     = azapi_resource.this.body.properties.eventHubReceivers[0].subscriptionId == "11111111-1111-1111-1111-111111111111"
    error_message = "Event hub receivers must support a namespace in another subscription."
  }
  assert {
    condition     = azapi_resource.this.body.properties.eventHubReceivers[0].tenantId == "22222222-2222-2222-2222-222222222222"
    error_message = "Event hub receivers must support a namespace in another tenant."
  }
  assert {
    condition     = azapi_resource.this.body.properties.itsmReceivers[0].region == "westcentralus"
    error_message = "The ITSM receiver must carry the connection region."
  }
  assert {
    condition     = azapi_resource.this.body.properties.logicAppReceivers[0].resourceId == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Logic/workflows/logic-avm-unit"
    error_message = "The Logic App receiver must carry the workflow resource ID."
  }
  assert {
    condition     = azapi_resource.this.body.properties.smsReceivers[0].countryCode == "44"
    error_message = "The SMS receiver must carry the country code."
  }
  assert {
    condition     = azapi_resource.this.body.properties.voiceReceivers[0].phoneNumber == "5555550100"
    error_message = "The voice receiver must carry the phone number."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.webhookReceivers) == 1
    error_message = "The webhook receiver must be sent to Azure."
  }
}

run "common_alert_schema_is_per_receiver" {
  command = apply

  variables {
    email_receivers = {
      modern = {
        name                    = "modern"
        email_address           = "modern@contoso.com"
        use_common_alert_schema = true
      }
      legacy = {
        name                    = "legacy"
        email_address           = "legacy@contoso.com"
        use_common_alert_schema = false
      }
    }
  }

  assert {
    condition     = length([for r in azapi_resource.this.body.properties.emailReceivers : r if r.useCommonAlertSchema]) == 1
    error_message = "Exactly one email receiver must have the common alert schema enabled."
  }
  assert {
    condition     = length([for r in azapi_resource.this.body.properties.emailReceivers : r if !r.useCommonAlertSchema]) == 1
    error_message = "Exactly one email receiver must have the common alert schema disabled."
  }
}

run "secure_webhook" {
  command = apply

  variables {
    webhook_receivers = {
      secure = {
        name                    = "secure"
        service_uri             = "https://example.com/secure"
        identifier_uri          = "api://avm-example"
        object_id               = "00000000-0000-0000-0000-000000000001"
        tenant_id               = "22222222-2222-2222-2222-222222222222"
        use_aad_auth            = true
        use_common_alert_schema = true
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.webhookReceivers[0].useAadAuth == true
    error_message = "Microsoft Entra authentication must be enabled on the secure webhook receiver."
  }
  assert {
    condition     = azapi_resource.this.body.properties.webhookReceivers[0].objectId == "00000000-0000-0000-0000-000000000001"
    error_message = "The secure webhook receiver must carry the Entra service principal object ID."
  }
  assert {
    condition     = azapi_resource.this.body.properties.webhookReceivers[0].identifierUri == "api://avm-example"
    error_message = "The secure webhook receiver must carry the Entra application identifier URI."
  }
}

run "credential_bearing_endpoints_are_sensitive" {
  command = apply

  variables {
    azure_function_receivers = {
      dispatcher = {
        name                     = "dispatcher"
        function_app_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Web/sites/func-avm-unit"
        function_name            = "DispatchAlert"
        http_trigger_url         = "https://example.com/api/dispatch"
      }
    }
    logic_app_receivers = {
      triage = {
        name         = "triage"
        resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Logic/workflows/logic-avm-unit"
        callback_url = "https://example.com/logic-callback"
      }
    }
    webhook_receivers = {
      ops = {
        name        = "ops"
        service_uri = "https://example.com/ops"
      }
    }
  }

  assert {
    condition     = issensitive(azapi_resource.this.body.properties.azureFunctionReceivers[0].httpTriggerUrl)
    error_message = "The Azure Function HTTP trigger URL must be marked sensitive."
  }
  assert {
    condition     = issensitive(azapi_resource.this.body.properties.logicAppReceivers[0].callbackUrl)
    error_message = "The Logic App callback URL must be marked sensitive."
  }
  assert {
    condition     = issensitive(azapi_resource.this.body.properties.webhookReceivers[0].serviceUri)
    error_message = "The webhook service URI must be marked sensitive."
  }
  assert {
    condition     = !issensitive(output.resource_id)
    error_message = "The resource ID output must not carry sensitive receiver data."
  }
}

run "receivers_can_be_added" {
  command = apply

  variables {
    email_receivers = {
      on_call = {
        name          = "on-call"
        email_address = "on-call@contoso.com"
      }
      owner = {
        name          = "owner"
        email_address = "owner@contoso.com"
      }
    }
    sms_receivers = {
      on_call = {
        name         = "on-call-sms"
        country_code = "44"
        phone_number = "1234567890"
      }
    }
  }

  assert {
    condition     = length(azapi_resource.this.body.properties.emailReceivers) == 2
    error_message = "Adding a receiver must update the action group in place."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.smsReceivers) == 1
    error_message = "Adding a receiver of a new type must update the action group in place."
  }
}

run "receivers_can_be_removed" {
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
    condition     = length(azapi_resource.this.body.properties.emailReceivers) == 1
    error_message = "Removing a receiver must update the action group in place."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.smsReceivers) == 0
    error_message = "Removing every receiver of a type must send an empty array."
  }
}

run "aliased_azapi_provider" {
  command = apply

  providers = {
    azapi  = azapi.alternate
    modtm  = modtm
    random = random
  }

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
    error_message = "The module must accept an aliased AzAPI provider configuration."
  }
}
