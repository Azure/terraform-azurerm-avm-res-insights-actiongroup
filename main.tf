resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.insights_action_groups
  body = {
    properties = {
      armRoleReceivers           = local.arm_role_receivers
      automationRunbookReceivers = local.automation_runbook_receivers
      azureAppPushReceivers      = local.azure_app_push_receivers
      azureFunctionReceivers     = local.azure_function_receivers
      emailReceivers             = local.email_receivers
      enabled                    = var.enabled
      eventHubReceivers          = local.event_hub_receivers
      groupShortName             = var.short_name
      itsmReceivers              = local.itsm_receivers
      logicAppReceivers          = local.logic_app_receivers
      smsReceivers               = local.sms_receivers
      voiceReceivers             = local.voice_receivers
      webhookReceivers           = local.webhook_receivers
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.insights_action_groups) > 0 ? var.ignore_body_changes.insights_action_groups : null
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    precondition {
      condition     = length(local.receiver_names) == length(distinct(local.receiver_names))
      error_message = "Receiver names must be unique across every receiver collection in the action group. Two or more receivers currently share an Azure-visible `name`."
    }
  }
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.7.0"

  enable_telemetry                 = var.enable_telemetry
  lock                             = var.lock
  role_assignment_definition_scope = azapi_resource.this.id
  role_assignments                 = var.role_assignments
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name                   = coalesce(module.avm_interfaces.lock_azapi.name, "lock-${var.lock.kind}")
  parent_id              = azapi_resource.this.id
  type                   = var.resource_types.authorization_locks
  body                   = module.avm_interfaces.lock_azapi.body
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource" "role_assignments" {
  for_each = module.avm_interfaces.role_assignments_azapi

  name                = each.value.name
  parent_id           = azapi_resource.this.id
  type                = var.resource_types.authorization_role_assignments
  body                = each.value.body
  ignore_body_changes = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  # Azure infers principalType server-side, so an unset value would otherwise drift on every plan.
  ignore_null_property   = true
  response_export_values = []
  retry                  = var.retry != null ? var.retry : local.role_assignment_retry_default

  dynamic "timeouts" {
    for_each = [var.timeouts != null ? var.timeouts : local.role_assignment_timeouts_default]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
