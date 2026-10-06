variable "location" {
  type        = string
  description = <<DESCRIPTION
Azure region of the action group. Azure Monitor action groups are global resources, so
`Global` is the expected value for virtually every deployment. Supply a regional value only
where Azure Monitor offers a regional action group for data-residency reasons.
DESCRIPTION
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the action group. This value maps to `Microsoft.Insights/actionGroups.name`."
  nullable    = false

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 260
    error_message = "`name` must be between 1 and 260 characters long."
  }
  validation {
    condition     = !can(regex("[<>*%&:\\\\?+/]", var.name))
    error_message = "`name` must not contain any of the characters `<`, `>`, `*`, `%`, `&`, `:`, `\\`, `?`, `+` or `/`."
  }
  validation {
    condition     = !endswith(var.name, ".") && !endswith(var.name, " ")
    error_message = "`name` must not end with a period or a space."
  }
}

variable "parent_id" {
  type        = string
  description = <<DESCRIPTION
The fully-qualified ARM resource ID of the resource group into which the action group is
deployed, for example
`/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg`.

This module **does not** create the parent scope. The consumer (or composing pattern module)
is responsible for providing a `parent_id` for an existing resource group.
DESCRIPTION
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid Azure resource group resource ID."
  }
}

variable "short_name" {
  type        = string
  description = <<DESCRIPTION
The short name of the action group. This value maps to
`Microsoft.Insights/actionGroups.properties.groupShortName` and is used as the sender
identity in SMS and voice notifications. Must be between 1 and 12 characters.
DESCRIPTION
  nullable    = false

  validation {
    condition     = length(trimspace(var.short_name)) > 0 && length(var.short_name) <= 12
    error_message = "`short_name` must be a non-blank string of at most 12 characters."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "enabled" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
Indicates whether this action group is enabled. This value maps to
`Microsoft.Insights/actionGroups.properties.enabled`. If an action group is not enabled then
none of its receivers will receive communications.
DESCRIPTION
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    insights_action_groups         = optional(list(string), [])
    authorization_locks            = optional(list(string), [])
    authorization_role_assignments = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Paths in each resource's `body` whose changes the AzAPI provider ignores. Prefer Terraform's
`lifecycle.ignore_changes` when the paths are static; use this variable when the paths must be
derived from variables or other non-static values.

Paths use dot notation, for example `properties.enabled` or `properties.emailReceivers`.
Individual list items cannot be targeted — ignore the whole list property instead.
Configuration changes at an ignored path are **not** sent to Azure until that path is removed
from the list.

Supplying a non-empty value requires Terraform 1.11 or later, because `ignore_body_changes` is
a write-only argument. Changes take effect only **after** an apply, because the value is held
in provider-private state. A consumer who adds a path still sees the pending diff in the same
plan, and a consumer who removes a path does not see the suppressed diff reappear until the
next plan.

- `insights_action_groups`         - Ignored body paths for the action group managed by this module.
- `authorization_locks`            - Ignored body paths for the optional management lock.
- `authorization_role_assignments` - Ignored body paths for the role assignments created on the action group.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind  = string
    name  = optional(string, null)
    notes = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
- `notes` - (Optional) Notes about the lock. This value maps to `Microsoft.Authorization/locks.properties.notes`.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "resource_types" {
  type = object({
    insights_action_groups         = optional(string, "Microsoft.Insights/actionGroups@2023-01-01")
    authorization_locks            = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
  })
  default     = {}
  description = <<DESCRIPTION
Override the AzAPI `<provider>/<resource>@<api-version>` strings used by this module. Each key
defaults to a tested value; supply only the keys you want to override. Useful when targeting a
sovereign cloud where an older API version is the latest available, or when opting into a newer
preview API without waiting for a module release.

- `insights_action_groups`         - The action group managed by this module.
- `authorization_locks`            - The optional management lock applied to the action group.
- `authorization_role_assignments` - The role assignments created on the action group.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every `azapi` resource managed by the module. Defaults to `null`
(no custom retry) for the action group and the management lock. Role assignments always retry on
`ScopeLocked`, which Azure raises while a just-removed management lock is still propagating; any
patterns supplied here are merged with that one rather than replacing it.

- `error_message_regex`  - (Optional) A list of regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.

See <https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#retry> for full semantics.
DESCRIPTION
}

variable "role_assignments" {
  type = map(object({
    name                                   = optional(string, null)
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the action group. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the role assignment. If not set, a random UUID will be generated. Changing this forces the creation of a new resource.
- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for _, v in var.role_assignments :
      v.delegated_managed_identity_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", v.delegated_managed_identity_resource_id))
    ])
    error_message = "Each `role_assignments[*].delegated_managed_identity_resource_id` must be a valid user-assigned managed identity resource ID, or null."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default per-operation timeouts applied to every `azapi` resource managed by the module.
Defaults to `null` (provider defaults) for the action group and the management lock. Role
assignments fall back to a module default of `delete = "5m"`; supplying a value here replaces
that default. Each value is a Go duration string (e.g. `30m`, `1h`).

- `create` - (Optional) Timeout for create operations.
- `read`   - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.
- `delete` - (Optional) Timeout for delete operations.
DESCRIPTION
}
