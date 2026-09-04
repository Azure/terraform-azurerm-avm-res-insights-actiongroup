mock_provider "azapi" {
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

run "short_name_too_long" {
  command = plan

  variables {
    short_name = "thisistoolongforazure"
  }

  expect_failures = [var.short_name]
}

run "short_name_blank" {
  command = plan

  variables {
    short_name = "   "
  }

  expect_failures = [var.short_name]
}

run "name_contains_forbidden_characters" {
  command = plan

  variables {
    name = "ag/avm-unit"
  }

  expect_failures = [var.name]
}

run "parent_id_is_not_a_resource_group" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.parent_id]
}

run "email_receiver_name_is_blank" {
  command = plan

  variables {
    email_receivers = {
      on_call = {
        name          = ""
        email_address = "on-call@contoso.com"
      }
    }
  }

  expect_failures = [var.email_receivers]
}

run "email_receiver_address_is_invalid" {
  command = plan

  variables {
    email_receivers = {
      on_call = {
        name          = "on-call"
        email_address = "not-an-email"
      }
    }
  }

  expect_failures = [var.email_receivers]
}

run "email_receiver_names_are_duplicated" {
  command = plan

  variables {
    email_receivers = {
      first = {
        name          = "on-call"
        email_address = "first@contoso.com"
      }
      second = {
        name          = "on-call"
        email_address = "second@contoso.com"
      }
    }
  }

  expect_failures = [var.email_receivers]
}

run "receiver_names_are_duplicated_across_collections" {
  command = plan

  variables {
    email_receivers = {
      on_call = {
        name          = "on-call"
        email_address = "on-call@contoso.com"
      }
    }
    sms_receivers = {
      on_call = {
        name         = "on-call"
        country_code = "44"
        phone_number = "1234567890"
      }
    }
  }

  expect_failures = [azapi_resource.this]
}

run "sms_receiver_country_code_is_invalid" {
  command = plan

  variables {
    sms_receivers = {
      on_call = {
        name         = "on-call-sms"
        country_code = "+44"
        phone_number = "1234567890"
      }
    }
  }

  expect_failures = [var.sms_receivers]
}

run "sms_receiver_phone_number_is_missing" {
  command = plan

  variables {
    sms_receivers = {
      on_call = {
        name         = "on-call-sms"
        country_code = "44"
        phone_number = ""
      }
    }
  }

  expect_failures = [var.sms_receivers]
}

run "voice_receiver_phone_number_is_invalid" {
  command = plan

  variables {
    voice_receivers = {
      escalation = {
        name         = "escalation-voice"
        country_code = "1"
        phone_number = "555-555-0100"
      }
    }
  }

  expect_failures = [var.voice_receivers]
}

run "webhook_receiver_service_uri_is_missing" {
  command = plan

  variables {
    webhook_receivers = {
      ops = {
        name        = "ops"
        service_uri = ""
      }
    }
  }

  expect_failures = [var.webhook_receivers]
}

run "secure_webhook_receiver_is_incomplete" {
  command = plan

  variables {
    webhook_receivers = {
      secure = {
        name         = "secure"
        service_uri  = "https://example.com/secure"
        use_aad_auth = true
      }
    }
  }

  expect_failures = [var.webhook_receivers]
}

run "azure_function_receiver_is_incomplete" {
  command = plan

  variables {
    azure_function_receivers = {
      dispatcher = {
        name                     = "dispatcher"
        function_app_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Web/sites/func-avm-unit"
        function_name            = ""
        http_trigger_url         = "https://example.com/api/dispatch"
      }
    }
  }

  expect_failures = [var.azure_function_receivers]
}

run "azure_function_receiver_resource_id_is_invalid" {
  command = plan

  variables {
    azure_function_receivers = {
      dispatcher = {
        name                     = "dispatcher"
        function_app_resource_id = "func-avm-unit"
        function_name            = "DispatchAlert"
        http_trigger_url         = "https://example.com/api/dispatch"
      }
    }
  }

  expect_failures = [var.azure_function_receivers]
}

run "logic_app_receiver_is_incomplete" {
  command = plan

  variables {
    logic_app_receivers = {
      triage = {
        name         = "triage"
        resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Logic/workflows/logic-avm-unit"
        callback_url = "logic-callback"
      }
    }
  }

  expect_failures = [var.logic_app_receivers]
}

run "event_hub_receiver_is_incomplete" {
  command = plan

  variables {
    event_hub_receivers = {
      stream = {
        name                = "stream"
        event_hub_namespace = "ehns-avm-unit"
        event_hub_name      = ""
        subscription_id     = "11111111-1111-1111-1111-111111111111"
      }
    }
  }

  expect_failures = [var.event_hub_receivers]
}

run "event_hub_receiver_subscription_id_is_invalid" {
  command = plan

  variables {
    event_hub_receivers = {
      stream = {
        name                = "stream"
        event_hub_namespace = "ehns-avm-unit"
        event_hub_name      = "eh-avm-unit"
        subscription_id     = "not-a-guid"
      }
    }
  }

  expect_failures = [var.event_hub_receivers]
}

run "arm_role_receiver_role_id_is_missing" {
  command = plan

  variables {
    arm_role_receivers = {
      monitoring_reader = {
        name    = "monitoring-reader"
        role_id = ""
      }
    }
  }

  expect_failures = [var.arm_role_receivers]
}

run "arm_role_receiver_role_id_is_not_a_guid" {
  command = plan

  variables {
    arm_role_receivers = {
      monitoring_reader = {
        name    = "monitoring-reader"
        role_id = "/providers/Microsoft.Authorization/roleDefinitions/43d0d8ad-25c7-4714-9337-8ba259a9fe05"
      }
    }
  }

  expect_failures = [var.arm_role_receivers]
}

run "automation_runbook_receiver_is_incomplete" {
  command = plan

  variables {
    automation_runbook_receivers = {
      remediation = {
        automation_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Automation/automationAccounts/aa-avm-unit"
        runbook_name          = ""
        webhook_resource_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Automation/automationAccounts/aa-avm-unit/webhooks/wh-avm-unit"
      }
    }
  }

  expect_failures = [var.automation_runbook_receivers]
}

run "automation_runbook_receiver_webhook_id_is_invalid" {
  command = plan

  variables {
    automation_runbook_receivers = {
      remediation = {
        automation_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Automation/automationAccounts/aa-avm-unit"
        runbook_name          = "Restart-Service"
        webhook_resource_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Automation/automationAccounts/aa-avm-unit"
      }
    }
  }

  expect_failures = [var.automation_runbook_receivers]
}

run "itsm_receiver_ticket_configuration_is_not_json" {
  command = plan

  variables {
    itsm_receivers = {
      snow = {
        name                 = "snow"
        workspace_id         = "00000000-0000-0000-0000-000000000000|33333333-3333-3333-3333-333333333333"
        connection_id        = "44444444-4444-4444-4444-444444444444"
        ticket_configuration = "not-json"
        region               = "westcentralus"
      }
    }
  }

  expect_failures = [var.itsm_receivers]
}

run "azure_app_push_receiver_address_is_invalid" {
  command = plan

  variables {
    azure_app_push_receivers = {
      mobile = {
        name          = "mobile"
        email_address = "mobile-at-contoso"
      }
    }
  }

  expect_failures = [var.azure_app_push_receivers]
}
