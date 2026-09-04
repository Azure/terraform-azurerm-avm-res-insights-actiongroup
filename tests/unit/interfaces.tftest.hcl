mock_provider "azapi" {
  # Child resources are parented on the action group's resource ID, so the mocked ID must be a
  # well formed ARM resource ID.
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-unit/providers/Microsoft.Insights/actionGroups/ag-avm-unit"
    }
  }
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
  email_receivers = {
    on_call = {
      name          = "on-call"
      email_address = "on-call@contoso.com"
    }
  }
}

run "lock" {
  command = apply

  variables {
    lock = {
      kind  = "CanNotDelete"
      notes = "Protected."
    }
  }

  assert {
    condition     = length(azapi_resource.lock) == 1
    error_message = "A management lock must be created when `lock` is supplied."
  }
  assert {
    condition     = azapi_resource.lock[0].type == "Microsoft.Authorization/locks@2020-05-01"
    error_message = "The lock must use the resource type from `resource_types`."
  }
  assert {
    condition     = azapi_resource.lock[0].parent_id == azapi_resource.this.id
    error_message = "The lock must be scoped to the action group."
  }
  assert {
    condition     = azapi_resource.lock[0].body.properties.level == "CanNotDelete"
    error_message = "The lock level must come from `lock.kind`."
  }
  assert {
    condition     = azapi_resource.lock[0].body.properties.notes == "Protected."
    error_message = "The lock notes must come from `lock.notes`."
  }
}

run "role_assignments" {
  command = apply

  variables {
    role_assignments = {
      monitoring_reader = {
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/43d0d8ad-25c7-4714-9337-8ba259a9fe05"
        principal_id               = "55555555-5555-5555-5555-555555555555"
        principal_type             = "ServicePrincipal"
      }
    }
  }

  assert {
    condition     = length(azapi_resource.role_assignments) == 1
    error_message = "A role assignment must be created for each `role_assignments` entry."
  }
  assert {
    condition     = azapi_resource.role_assignments["monitoring_reader"].type == "Microsoft.Authorization/roleAssignments@2022-04-01"
    error_message = "The role assignment must use the resource type from `resource_types`."
  }
  assert {
    condition     = azapi_resource.role_assignments["monitoring_reader"].parent_id == azapi_resource.this.id
    error_message = "The role assignment must be scoped to the action group."
  }
  assert {
    condition     = azapi_resource.role_assignments["monitoring_reader"].body.properties.principalId == "55555555-5555-5555-5555-555555555555"
    error_message = "The role assignment must carry the supplied principal ID."
  }
  assert {
    condition     = contains(azapi_resource.role_assignments["monitoring_reader"].retry.error_message_regex, "ScopeLocked")
    error_message = "Role assignments must retry the transient `ScopeLocked` error raised while a lock is being removed."
  }
}

run "azapi_control_interfaces" {
  command = apply

  variables {
    ignore_body_changes = {
      insights_action_groups = ["tags", "properties.enabled"]
    }
    resource_types = {
      insights_action_groups = "Microsoft.Insights/actionGroups@2022-06-01"
    }
    retry = {
      error_message_regex  = ["ResourceGroupNotFound"]
      interval_seconds     = 10
      max_interval_seconds = 60
    }
    timeouts = {
      create = "10m"
      delete = "11m"
      read   = "12m"
      update = "13m"
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Insights/actionGroups@2022-06-01"
    error_message = "`resource_types` must override the action group API version."
  }
  # `ignore_body_changes` is a write-only AzAPI argument. It is held in provider private state and
  # always reads back as null, so it cannot be asserted from the plan or from state. The wiring is
  # covered by `terraform validate` and by the `complete` example.
  assert {
    condition     = azapi_resource.this.retry.interval_seconds == 10
    error_message = "`retry` must be forwarded to the action group resource."
  }
  assert {
    condition     = azapi_resource.this.timeouts.create == "10m"
    error_message = "`timeouts` must be forwarded to the action group resource."
  }
  assert {
    condition     = azapi_resource.this.timeouts.delete == "11m"
    error_message = "`timeouts` must be forwarded to the action group resource."
  }
  assert {
    condition     = azapi_resource.this.timeouts.read == "12m"
    error_message = "`timeouts` must be forwarded to the action group resource."
  }
  assert {
    condition     = azapi_resource.this.timeouts.update == "13m"
    error_message = "`timeouts` must be forwarded to the action group resource."
  }
}
