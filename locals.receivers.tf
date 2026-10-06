locals {
  arm_role_receivers = [
    for k, v in var.arm_role_receivers : {
      name                 = v.name
      roleId               = v.role_id
      useCommonAlertSchema = v.use_common_alert_schema
    }
  ]
  automation_runbook_receivers = [
    for k, v in var.automation_runbook_receivers : {
      automationAccountId  = v.automation_account_id
      isGlobalRunbook      = v.is_global_runbook
      name                 = v.name
      runbookName          = v.runbook_name
      useCommonAlertSchema = v.use_common_alert_schema
      webhookResourceId    = v.webhook_resource_id
    }
  ]
  azure_app_push_receivers = [
    for k, v in var.azure_app_push_receivers : {
      emailAddress = v.email_address
      name         = v.name
    }
  ]
  azure_function_receivers = [
    for k, v in var.azure_function_receivers : {
      functionAppResourceId = v.function_app_resource_id
      functionName          = v.function_name
      name                  = v.name
      useCommonAlertSchema  = v.use_common_alert_schema
    }
  ]
  email_receivers = [
    for k, v in var.email_receivers : {
      emailAddress         = v.email_address
      name                 = v.name
      useCommonAlertSchema = v.use_common_alert_schema
    }
  ]
  event_hub_receivers = [
    for k, v in var.event_hub_receivers : {
      eventHubName         = v.event_hub_name
      eventHubNameSpace    = v.event_hub_namespace
      name                 = v.name
      subscriptionId       = v.subscription_id
      tenantId             = v.tenant_id
      useCommonAlertSchema = v.use_common_alert_schema
    }
  ]
  itsm_receivers = [
    for k, v in var.itsm_receivers : {
      connectionId        = v.connection_id
      name                = v.name
      region              = v.region
      ticketConfiguration = v.ticket_configuration
      workspaceId         = v.workspace_id
    }
  ]
  logic_app_receivers = [
    for k, v in var.logic_app_receivers : {
      name                 = v.name
      resourceId           = v.resource_id
      useCommonAlertSchema = v.use_common_alert_schema
    }
  ]
  # Azure requires every receiver name to be unique across the whole action group, not just
  # within a single receiver collection. Automation runbook receiver names are optional.
  receiver_names = concat(
    [for v in values(var.arm_role_receivers) : v.name],
    [for v in values(var.automation_runbook_receivers) : v.name if v.name != null],
    [for v in values(var.azure_app_push_receivers) : v.name],
    [for v in values(var.azure_function_receivers) : v.name],
    [for v in values(var.email_receivers) : v.name],
    [for v in values(var.event_hub_receivers) : v.name],
    [for v in values(var.itsm_receivers) : v.name],
    [for v in values(var.logic_app_receivers) : v.name],
    [for v in values(var.sms_receivers) : v.name],
    [for v in values(var.voice_receivers) : v.name],
    [for v in values(var.webhook_receivers) : v.name],
  )
  sms_receivers = [
    for k, v in var.sms_receivers : {
      countryCode = v.country_code
      name        = v.name
      phoneNumber = v.phone_number
    }
  ]
  voice_receivers = [
    for k, v in var.voice_receivers : {
      countryCode = v.country_code
      name        = v.name
      phoneNumber = v.phone_number
    }
  ]
  webhook_receivers = [
    for k, v in var.webhook_receivers : {
      identifierUri        = v.identifier_uri
      name                 = v.name
      objectId             = v.object_id
      tenantId             = v.tenant_id
      useAadAuth           = v.use_aad_auth
      useCommonAlertSchema = v.use_common_alert_schema
    }
  ]
}

locals {
  # Credential-bearing endpoints travel in `sensitive_body`, which is write-only, so they never
  # reach Terraform state. Each list position matches the same receiver in `body` because both
  # iterate the same map, and Terraform iterates a map in sorted key order.
  automation_runbook_receivers_sensitive = [
    for k, v in var.automation_runbook_receivers : {
      name       = v.name
      serviceUri = v.service_uri
    }
  ]
  azure_function_receivers_sensitive = [
    for k, v in var.azure_function_receivers : {
      httpTriggerUrl = v.http_trigger_url
      name           = v.name
    }
  ]
  logic_app_receivers_sensitive = [
    for k, v in var.logic_app_receivers : {
      callbackUrl = v.callback_url
      name        = v.name
    }
  ]
  webhook_receivers_sensitive = [
    for k, v in var.webhook_receivers : {
      name       = v.name
      serviceUri = v.service_uri
    }
  ]
  sensitive_receiver_body = {
    properties = {
      automationRunbookReceivers = local.automation_runbook_receivers_sensitive
      azureFunctionReceivers     = local.azure_function_receivers_sensitive
      logicAppReceivers          = local.logic_app_receivers_sensitive
      webhookReceivers           = local.webhook_receivers_sensitive
    }
  }
  # Hashing the endpoint, rather than versioning it by hand, makes a changed secret detectable
  # without the secret itself being written to state.
  sensitive_receiver_versions = merge(
    { for i, v in local.automation_runbook_receivers_sensitive : "properties.automationRunbookReceivers[${i}].serviceUri" => sha256(v.serviceUri == null ? "" : v.serviceUri) },
    { for i, v in local.azure_function_receivers_sensitive : "properties.azureFunctionReceivers[${i}].httpTriggerUrl" => sha256(v.httpTriggerUrl) },
    { for i, v in local.logic_app_receivers_sensitive : "properties.logicAppReceivers[${i}].callbackUrl" => sha256(v.callbackUrl) },
    { for i, v in local.webhook_receivers_sensitive : "properties.webhookReceivers[${i}].serviceUri" => sha256(v.serviceUri) },
  )
  # Collapsing to null when no credential-bearing receiver is configured keeps the module usable
  # on Terraform versions earlier than 1.11, which cannot accept a write-only argument.
  has_sensitive_receivers = length(local.sensitive_receiver_versions) > 0
}
