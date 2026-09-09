variable "arm_role_receivers" {
  type = map(object({
    name                    = string
    role_id                 = string
    use_common_alert_schema = optional(bool, false)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of ARM role receivers to add to the action group. Maps to
`Microsoft.Insights/actionGroups.properties.armRoleReceivers`. Only built-in Azure RBAC roles
are supported by Azure. The map key is deliberately arbitrary: it controls Terraform identity
only and is never sent to Azure.

- `name`                    - (Required) The Azure-visible name of the receiver. Names must be unique across **all** receivers within the action group.
- `role_id`                 - (Required) The bare GUID of the built-in role definition, for example `8e3af657-a8ff-443c-a75c-2fe8c4bcb635` for Owner. A fully-qualified role definition resource ID is not accepted by Azure.
- `use_common_alert_schema` - (Optional) Whether to use the common alert schema. Defaults to `false`.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.arm_role_receivers) : length(trimspace(v.name)) > 0])
    error_message = "Each `arm_role_receivers[*].name` must be a non-blank string."
  }
  validation {
    condition     = alltrue([for v in values(var.arm_role_receivers) : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", v.role_id))])
    error_message = "Each `arm_role_receivers[*].role_id` must be the bare GUID of a built-in Azure role definition."
  }
  validation {
    condition     = length(distinct([for v in values(var.arm_role_receivers) : v.name])) == length(var.arm_role_receivers)
    error_message = "Each `arm_role_receivers[*].name` must be unique."
  }
}

variable "automation_runbook_receivers" {
  type = map(object({
    automation_account_id   = string
    runbook_name            = string
    webhook_resource_id     = string
    is_global_runbook       = optional(bool, false)
    name                    = optional(string, null)
    service_uri             = optional(string, null)
    use_common_alert_schema = optional(bool, false)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Automation runbook receivers to add to the action group. Maps to
`Microsoft.Insights/actionGroups.properties.automationRunbookReceivers`. The map key is
deliberately arbitrary: it controls Terraform identity only and is never sent to Azure.

- `automation_account_id`   - (Required) The resource ID of the Azure Automation account that holds the runbook.
- `runbook_name`            - (Required) The name of the runbook to start.
- `webhook_resource_id`     - (Required) The resource ID of the Automation webhook linked to the runbook.
- `is_global_runbook`       - (Optional) Whether this instance is a global runbook. Defaults to `false`.
- `name`                    - (Optional) The Azure-visible name of the webhook receiver. When set it must be unique across **all** receivers within the action group.
- `service_uri`             - (Optional) The URI the webhook request is sent to. **Credential bearing**: Automation webhook URIs embed a single-use token and are persisted in Terraform state.
- `use_common_alert_schema` - (Optional) Whether to use the common alert schema. Defaults to `false`.
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for v in values(var.automation_runbook_receivers) :
      can(provider::azapi::parse_resource_id("Microsoft.Automation/automationAccounts", v.automation_account_id))
    ])
    error_message = "Each `automation_runbook_receivers[*].automation_account_id` must be a valid Azure Automation account resource ID."
  }
  validation {
    condition = alltrue([
      for v in values(var.automation_runbook_receivers) :
      can(provider::azapi::parse_resource_id("Microsoft.Automation/automationAccounts/webhooks", v.webhook_resource_id))
    ])
    error_message = "Each `automation_runbook_receivers[*].webhook_resource_id` must be a valid Azure Automation webhook resource ID."
  }
  validation {
    condition     = alltrue([for v in values(var.automation_runbook_receivers) : length(trimspace(v.runbook_name)) > 0])
    error_message = "Each `automation_runbook_receivers[*].runbook_name` must be a non-blank string."
  }
  validation {
    condition     = alltrue([for v in values(var.automation_runbook_receivers) : v.service_uri == null || can(regex("^https?://", coalesce(v.service_uri, "-")))])
    error_message = "Each `automation_runbook_receivers[*].service_uri`, when supplied, must be an absolute HTTP or HTTPS URI. HTTPS is strongly recommended."
  }
  validation {
    condition     = length(distinct([for v in values(var.automation_runbook_receivers) : v.name if v.name != null])) == length([for v in values(var.automation_runbook_receivers) : v.name if v.name != null])
    error_message = "Each `automation_runbook_receivers[*].name`, when supplied, must be unique."
  }
}

variable "azure_app_push_receivers" {
  type = map(object({
    name          = string
    email_address = string
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure mobile app push receivers to add to the action group. Maps to
`Microsoft.Insights/actionGroups.properties.azureAppPushReceivers`. The map key is
deliberately arbitrary: it controls Terraform identity only and is never sent to Azure.

Azure app push receivers do not support the common alert schema, so no
`use_common_alert_schema` attribute is exposed.

- `name`          - (Required) The Azure-visible name of the receiver. Names must be unique across **all** receivers within the action group.
- `email_address` - (Required) The email address registered with the Azure mobile app.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.azure_app_push_receivers) : length(trimspace(v.name)) > 0])
    error_message = "Each `azure_app_push_receivers[*].name` must be a non-blank string."
  }
  validation {
    condition     = alltrue([for v in values(var.azure_app_push_receivers) : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", v.email_address))])
    error_message = "Each `azure_app_push_receivers[*].email_address` must be a valid email address."
  }
  validation {
    condition     = length(distinct([for v in values(var.azure_app_push_receivers) : v.name])) == length(var.azure_app_push_receivers)
    error_message = "Each `azure_app_push_receivers[*].name` must be unique."
  }
}

variable "azure_function_receivers" {
  type = map(object({
    name                     = string
    function_app_resource_id = string
    function_name            = string
    http_trigger_url         = string
    use_common_alert_schema  = optional(bool, false)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Function receivers to add to the action group. Maps to
`Microsoft.Insights/actionGroups.properties.azureFunctionReceivers`. The map key is
deliberately arbitrary: it controls Terraform identity only and is never sent to Azure.

- `name`                     - (Required) The Azure-visible name of the receiver. Names must be unique across **all** receivers within the action group.
- `function_app_resource_id` - (Required) The resource ID of the function app.
- `function_name`            - (Required) The name of the function within the function app.
- `http_trigger_url`         - (Required) The HTTP trigger URL the request is sent to. **Credential bearing**: function trigger URLs usually embed a function key and are persisted in Terraform state.
- `use_common_alert_schema`  - (Optional) Whether to use the common alert schema. Defaults to `false`.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.azure_function_receivers) : length(trimspace(v.name)) > 0])
    error_message = "Each `azure_function_receivers[*].name` must be a non-blank string."
  }
  validation {
    condition = alltrue([
      for v in values(var.azure_function_receivers) :
      can(provider::azapi::parse_resource_id("Microsoft.Web/sites", v.function_app_resource_id))
    ])
    error_message = "Each `azure_function_receivers[*].function_app_resource_id` must be a valid function app (`Microsoft.Web/sites`) resource ID."
  }
  validation {
    condition     = alltrue([for v in values(var.azure_function_receivers) : length(trimspace(v.function_name)) > 0])
    error_message = "Each `azure_function_receivers[*].function_name` must be a non-blank string."
  }
  validation {
    condition     = alltrue([for v in values(var.azure_function_receivers) : can(regex("^https?://", v.http_trigger_url))])
    error_message = "Each `azure_function_receivers[*].http_trigger_url` must be an absolute HTTP or HTTPS URI. HTTPS is strongly recommended."
  }
  validation {
    condition     = length(distinct([for v in values(var.azure_function_receivers) : v.name])) == length(var.azure_function_receivers)
    error_message = "Each `azure_function_receivers[*].name` must be unique."
  }
}

variable "email_receivers" {
  type = map(object({
    name                    = string
    email_address           = string
    use_common_alert_schema = optional(bool, false)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of email receivers to add to the action group. Maps to
`Microsoft.Insights/actionGroups.properties.emailReceivers`. The map key is deliberately
arbitrary: it controls Terraform identity only and is never sent to Azure.

The Azure-side `status` of an email receiver is read-only and is therefore not exposed as an
input.

- `name`                    - (Required) The Azure-visible name of the receiver. Names must be unique across **all** receivers within the action group.
- `email_address`           - (Required) The email address of the receiver.
- `use_common_alert_schema` - (Optional) Whether to use the common alert schema. Defaults to `false`.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.email_receivers) : length(trimspace(v.name)) > 0])
    error_message = "Each `email_receivers[*].name` must be a non-blank string."
  }
  validation {
    condition     = alltrue([for v in values(var.email_receivers) : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", v.email_address))])
    error_message = "Each `email_receivers[*].email_address` must be a valid email address."
  }
  validation {
    condition     = length(distinct([for v in values(var.email_receivers) : v.name])) == length(var.email_receivers)
    error_message = "Each `email_receivers[*].name` must be unique."
  }
}

variable "event_hub_receivers" {
  type = map(object({
    name                    = string
    event_hub_namespace     = string
    event_hub_name          = string
    subscription_id         = string
    tenant_id               = optional(string, null)
    use_common_alert_schema = optional(bool, false)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Event Hub receivers to add to the action group. Maps to
`Microsoft.Insights/actionGroups.properties.eventHubReceivers`. The map key is deliberately
arbitrary: it controls Terraform identity only and is never sent to Azure.

Azure Monitor authenticates to the Event Hub with a managed identity, so no connection string
or shared access key is accepted or stored.

- `name`                    - (Required) The Azure-visible name of the receiver. Names must be unique across **all** receivers within the action group.
- `event_hub_namespace`     - (Required) The Event Hub namespace name (not a resource ID).
- `event_hub_name`          - (Required) The name of the Event Hub within the namespace.
- `subscription_id`         - (Required) The ID of the subscription containing the Event Hub. May differ from the action group's subscription.
- `tenant_id`               - (Optional) The tenant ID of the subscription containing the Event Hub.
- `use_common_alert_schema` - (Optional) Whether to use the common alert schema. Defaults to `false`.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.event_hub_receivers) : length(trimspace(v.name)) > 0])
    error_message = "Each `event_hub_receivers[*].name` must be a non-blank string."
  }
  validation {
    condition     = alltrue([for v in values(var.event_hub_receivers) : length(trimspace(v.event_hub_namespace)) > 0 && length(trimspace(v.event_hub_name)) > 0])
    error_message = "Each `event_hub_receivers[*].event_hub_namespace` and `event_hub_receivers[*].event_hub_name` must be non-blank strings."
  }
  validation {
    condition     = alltrue([for v in values(var.event_hub_receivers) : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", v.subscription_id))])
    error_message = "Each `event_hub_receivers[*].subscription_id` must be a GUID."
  }
  validation {
    condition     = alltrue([for v in values(var.event_hub_receivers) : v.tenant_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", coalesce(v.tenant_id, "-")))])
    error_message = "Each `event_hub_receivers[*].tenant_id`, when supplied, must be a GUID."
  }
  validation {
    condition     = length(distinct([for v in values(var.event_hub_receivers) : v.name])) == length(var.event_hub_receivers)
    error_message = "Each `event_hub_receivers[*].name` must be unique."
  }
}

variable "itsm_receivers" {
  type = map(object({
    name                 = string
    workspace_id         = string
    connection_id        = string
    ticket_configuration = string
    region               = string
  }))
  default     = {}
  description = <<DESCRIPTION
A map of ITSM receivers to add to the action group. Maps to
`Microsoft.Insights/actionGroups.properties.itsmReceivers`. The map key is deliberately
arbitrary: it controls Terraform identity only and is never sent to Azure.

ITSM receivers do not support the common alert schema, so no `use_common_alert_schema`
attribute is exposed.

- `name`                 - (Required) The Azure-visible name of the receiver. Names must be unique across **all** receivers within the action group.
- `workspace_id`         - (Required) The Log Analytics (OMS) workspace identifier that hosts the ITSM connection.
- `connection_id`        - (Required) The unique identifier of the ITSM connection within the workspace.
- `ticket_configuration` - (Required) A JSON document describing the ITSM action configuration. `CreateMultipleWorkItems` is part of this document.
- `region`               - (Required) The region in which the workspace resides. Azure currently documents `centralindia`, `japaneast`, `southeastasia`, `australiasoutheast`, `uksouth`, `westcentralus`, `canadacentral`, `eastus` and `westeurope`. The value is not constrained by this module because Azure adds regions over time.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.itsm_receivers) : length(trimspace(v.name)) > 0])
    error_message = "Each `itsm_receivers[*].name` must be a non-blank string."
  }
  validation {
    condition     = alltrue([for v in values(var.itsm_receivers) : length(trimspace(v.workspace_id)) > 0 && length(trimspace(v.connection_id)) > 0 && length(trimspace(v.region)) > 0])
    error_message = "Each `itsm_receivers[*]` must supply a non-blank `workspace_id`, `connection_id` and `region`."
  }
  validation {
    condition     = alltrue([for v in values(var.itsm_receivers) : can(jsondecode(v.ticket_configuration))])
    error_message = "Each `itsm_receivers[*].ticket_configuration` must be a valid JSON document."
  }
  validation {
    condition     = length(distinct([for v in values(var.itsm_receivers) : v.name])) == length(var.itsm_receivers)
    error_message = "Each `itsm_receivers[*].name` must be unique."
  }
}

variable "logic_app_receivers" {
  type = map(object({
    name                    = string
    resource_id             = string
    callback_url            = string
    use_common_alert_schema = optional(bool, false)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Logic App receivers to add to the action group. Maps to
`Microsoft.Insights/actionGroups.properties.logicAppReceivers`. The map key is deliberately
arbitrary: it controls Terraform identity only and is never sent to Azure.

- `name`                    - (Required) The Azure-visible name of the receiver. Names must be unique across **all** receivers within the action group.
- `resource_id`             - (Required) The resource ID of the Logic App workflow.
- `callback_url`            - (Required) The callback URL the HTTP request is sent to. **Credential bearing**: Logic App callback URLs embed a shared access signature and are persisted in Terraform state.
- `use_common_alert_schema` - (Optional) Whether to use the common alert schema. Defaults to `false`.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.logic_app_receivers) : length(trimspace(v.name)) > 0])
    error_message = "Each `logic_app_receivers[*].name` must be a non-blank string."
  }
  validation {
    condition = alltrue([
      for v in values(var.logic_app_receivers) :
      can(provider::azapi::parse_resource_id("Microsoft.Logic/workflows", v.resource_id))
    ])
    error_message = "Each `logic_app_receivers[*].resource_id` must be a valid Logic App workflow (`Microsoft.Logic/workflows`) resource ID."
  }
  validation {
    condition     = alltrue([for v in values(var.logic_app_receivers) : can(regex("^https?://", v.callback_url))])
    error_message = "Each `logic_app_receivers[*].callback_url` must be an absolute HTTP or HTTPS URI. HTTPS is strongly recommended."
  }
  validation {
    condition     = length(distinct([for v in values(var.logic_app_receivers) : v.name])) == length(var.logic_app_receivers)
    error_message = "Each `logic_app_receivers[*].name` must be unique."
  }
}

variable "sms_receivers" {
  type = map(object({
    name         = string
    country_code = string
    phone_number = string
  }))
  default     = {}
  description = <<DESCRIPTION
A map of SMS receivers to add to the action group. Maps to
`Microsoft.Insights/actionGroups.properties.smsReceivers`. The map key is deliberately
arbitrary: it controls Terraform identity only and is never sent to Azure.

SMS receivers do not support the common alert schema, so no `use_common_alert_schema`
attribute is exposed. The Azure-side `status` of an SMS receiver is read-only and is therefore
not exposed as an input.

- `name`         - (Required) The Azure-visible name of the receiver. Names must be unique across **all** receivers within the action group.
- `country_code` - (Required) The country dialling code, digits only and without a leading `+`, for example `1` or `44`.
- `phone_number` - (Required) The subscriber phone number, digits only and without the country code.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.sms_receivers) : length(trimspace(v.name)) > 0])
    error_message = "Each `sms_receivers[*].name` must be a non-blank string."
  }
  validation {
    condition     = alltrue([for v in values(var.sms_receivers) : can(regex("^[0-9]{1,4}$", v.country_code))])
    error_message = "Each `sms_receivers[*].country_code` must be 1 to 4 digits with no leading `+`."
  }
  validation {
    condition     = alltrue([for v in values(var.sms_receivers) : can(regex("^[0-9]{1,15}$", v.phone_number))])
    error_message = "Each `sms_receivers[*].phone_number` must be 1 to 15 digits with no separators or country code."
  }
  validation {
    condition     = length(distinct([for v in values(var.sms_receivers) : v.name])) == length(var.sms_receivers)
    error_message = "Each `sms_receivers[*].name` must be unique."
  }
}

variable "voice_receivers" {
  type = map(object({
    name         = string
    country_code = string
    phone_number = string
  }))
  default     = {}
  description = <<DESCRIPTION
A map of voice receivers to add to the action group. Maps to
`Microsoft.Insights/actionGroups.properties.voiceReceivers`. The map key is deliberately
arbitrary: it controls Terraform identity only and is never sent to Azure.

Voice receivers do not support the common alert schema, so no `use_common_alert_schema`
attribute is exposed.

- `name`         - (Required) The Azure-visible name of the receiver. Names must be unique across **all** receivers within the action group.
- `country_code` - (Required) The country dialling code, digits only and without a leading `+`, for example `1` or `44`.
- `phone_number` - (Required) The subscriber phone number, digits only and without the country code.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.voice_receivers) : length(trimspace(v.name)) > 0])
    error_message = "Each `voice_receivers[*].name` must be a non-blank string."
  }
  validation {
    condition     = alltrue([for v in values(var.voice_receivers) : can(regex("^[0-9]{1,4}$", v.country_code))])
    error_message = "Each `voice_receivers[*].country_code` must be 1 to 4 digits with no leading `+`."
  }
  validation {
    condition     = alltrue([for v in values(var.voice_receivers) : can(regex("^[0-9]{1,15}$", v.phone_number))])
    error_message = "Each `voice_receivers[*].phone_number` must be 1 to 15 digits with no separators or country code."
  }
  validation {
    condition     = length(distinct([for v in values(var.voice_receivers) : v.name])) == length(var.voice_receivers)
    error_message = "Each `voice_receivers[*].name` must be unique."
  }
}

variable "webhook_receivers" {
  type = map(object({
    name                    = string
    service_uri             = string
    use_common_alert_schema = optional(bool, false)
    use_aad_auth            = optional(bool, false)
    object_id               = optional(string, null)
    identifier_uri          = optional(string, null)
    tenant_id               = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of webhook receivers to add to the action group. Maps to
`Microsoft.Insights/actionGroups.properties.webhookReceivers`. The map key is deliberately
arbitrary: it controls Terraform identity only and is never sent to Azure.

Set `use_aad_auth` to `true` to configure a secure webhook, where Azure Monitor obtains a
Microsoft Entra ID token for the target application instead of calling an unauthenticated
endpoint. Secure webhooks are the recommended configuration.

- `name`                    - (Required) The Azure-visible name of the receiver. Names must be unique across **all** receivers within the action group.
- `service_uri`             - (Required) The URI webhooks are sent to. **Credential bearing** when the endpoint authenticates with a URL-embedded token; the value is persisted in Terraform state.
- `use_common_alert_schema` - (Optional) Whether to use the common alert schema. Defaults to `false`.
- `use_aad_auth`            - (Optional) Whether to use Microsoft Entra ID authentication (secure webhook). Defaults to `false`.
- `object_id`               - (Required when `use_aad_auth` is `true`) The object ID of the Entra ID application that receives the webhook.
- `identifier_uri`          - (Required when `use_aad_auth` is `true`) The Application ID URI of the Entra ID application that receives the webhook.
- `tenant_id`               - (Optional) The tenant ID used for Entra ID authentication. Defaults to the action group's tenant.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.webhook_receivers) : length(trimspace(v.name)) > 0])
    error_message = "Each `webhook_receivers[*].name` must be a non-blank string."
  }
  validation {
    condition     = alltrue([for v in values(var.webhook_receivers) : can(regex("^https?://", v.service_uri))])
    error_message = "Each `webhook_receivers[*].service_uri` must be an absolute HTTP or HTTPS URI. HTTPS is strongly recommended."
  }
  validation {
    condition     = alltrue([for v in values(var.webhook_receivers) : !v.use_aad_auth || (v.object_id != null && v.identifier_uri != null)])
    error_message = "Each `webhook_receivers[*]` with `use_aad_auth = true` must also supply `object_id` and `identifier_uri`."
  }
  validation {
    condition     = alltrue([for v in values(var.webhook_receivers) : v.object_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", coalesce(v.object_id, "-")))])
    error_message = "Each `webhook_receivers[*].object_id`, when supplied, must be a GUID."
  }
  validation {
    condition     = alltrue([for v in values(var.webhook_receivers) : v.tenant_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", coalesce(v.tenant_id, "-")))])
    error_message = "Each `webhook_receivers[*].tenant_id`, when supplied, must be a GUID."
  }
  validation {
    condition     = length(distinct([for v in values(var.webhook_receivers) : v.name])) == length(var.webhook_receivers)
    error_message = "Each `webhook_receivers[*].name` must be unique."
  }
}
