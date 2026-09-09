# Azure Monitor action group

This Azure Verified Module creates and manages an [Azure Monitor action group](https://learn.microsoft.com/azure/azure-monitor/alerts/action-groups)
(`Microsoft.Insights/actionGroups`).

An action group is a reusable, global collection of notification and automation receivers that
alert rules, Service Health alerts and Azure Advisor recommendations invoke when they fire.

## AzAPI-only design

Every Azure control-plane operation in this module, its examples and its tests is performed with
the [`Azure/azapi`](https://registry.terraform.io/providers/Azure/azapi/latest) provider.
**The `hashicorp/azurerm` provider is not required, is not declared anywhere in this repository,
and no `azurerm_*` resource or data source is used.** Request bodies are built from native
Terraform values rather than with `jsonencode`.

The module declares no provider configuration of its own, so a consumer may pass any AzAPI
provider configuration, including an aliased one, through the module's `providers` argument.

## API version

The module targets `Microsoft.Insights/actionGroups@2023-01-01`, the latest **stable** API version
for the resource type. The ARM REST API schema is the source of truth for the input surface; the
AzureRM provider's action group schema was not used.

Later preview versions exist (`2023-09-01-preview` and `2024-10-01-preview`, which add
`incidentReceivers`). AVM prefers a stable API version, so preview versions are not the default.
A consumer who needs one can override the resource type through the `resource_types` variable, but
must supply any preview-only properties themselves; the module exposes no typed inputs for them.

## Supported receiver types

| Receiver | Variable | Common alert schema |
| --- | --- | --- |
| Email | `email_receivers` | Yes |
| SMS | `sms_receivers` | Not supported by Azure |
| Voice | `voice_receivers` | Not supported by Azure |
| Azure mobile app push | `azure_app_push_receivers` | Not supported by Azure |
| Webhook, including secure Microsoft Entra authenticated webhooks | `webhook_receivers` | Yes |
| Azure Function | `azure_function_receivers` | Yes |
| Logic App | `logic_app_receivers` | Yes |
| Automation runbook | `automation_runbook_receivers` | Yes |
| Event hub | `event_hub_receivers` | Yes |
| ITSM | `itsm_receivers` | Not supported by Azure |
| ARM role | `arm_role_receivers` | Yes |

Each receiver collection is a **map keyed by an arbitrary, stable Terraform key**. The map key
controls Terraform identity only; the Azure-visible receiver name always comes from the `name`
attribute. Choosing keys independently of names lets you rename a receiver in Azure without
churning Terraform addresses, and vice versa.

Every collection defaults to an empty map, and unused collections are sent to Azure as empty
arrays. Azure permits an action group with no receivers at all, so the module does not require
one.

Receiver names must be unique across **all** collections in a single action group. The module
enforces this with a resource precondition, in addition to per-collection uniqueness validation.

### Common alert schema

`use_common_alert_schema` is a per-receiver setting on the receiver types listed above and
defaults to `false`, matching the Azure default. Azure does not model a common alert schema
setting for SMS, voice, Azure mobile app push or ITSM receivers, so the module does not expose one
for those types.

### Receiver activation and verification

Some receiver types are not active the moment Terraform reports success:

- **Email**, **SMS**, **voice** and **Azure mobile app push** receivers have an activation
  `status` that Azure manages. An email receiver, for example, stays unconfirmed until the
  recipient accepts the subscription.
- Activation state is a **read-only** ARM property. It is not exposed as a module input, is not
  read back into module outputs, and it never causes Terraform drift.
- **Secure webhook** receivers additionally require the target Microsoft Entra application to have
  been granted access by Azure Monitor. That grant is a Microsoft Graph operation and is outside
  the scope of this module.

## Sensitive values and Terraform state

Some receiver endpoints are credential-bearing URLs. The module marks the following values as
sensitive so that they are redacted from plan output and from any module output:

- `webhook_receivers[*].service_uri`
- `azure_function_receivers[*].http_trigger_url`
- `logic_app_receivers[*].callback_url`
- `automation_runbook_receivers[*].service_uri`

Marking a value sensitive changes how Terraform *displays* it. It does **not** encrypt it.
**All four values are stored in plaintext in Terraform state**, as is every other input you
supply, including phone numbers and email addresses. Protect state accordingly: use a remote
backend with encryption at rest, restrict read access to it, and prefer receiver types that carry
no secret.

The module deliberately exposes **no output** containing receiver bodies, webhook addresses,
callback URLs, HTTP trigger URLs, tokens or credentials. Only the action group's resource ID,
name, parent resource ID and the resource IDs of any role assignments are returned.

Where you have a choice, prefer identity-based integration: a **secure webhook**
(`use_aad_auth = true`) authenticates with a Microsoft Entra token issued at delivery time and
stores no secret in the configuration or in state at all. The `secure_webhook` example
demonstrates this.

## AVM interfaces

Implemented:

| Interface | Notes |
| --- | --- |
| `tags` | `Microsoft.Insights/actionGroups` is a taggable resource type. |
| `lock` | Deployed as `Microsoft.Authorization/locks`, scoped to the action group. |
| `role_assignments` | Deployed as `Microsoft.Authorization/roleAssignments`, scoped to the action group. |
| `resource_types`, `retry`, `timeouts`, `ignore_body_changes` | AzAPI control interfaces. |
| `parent_id`, `location`, `enable_telemetry` | Standard AVM resource module inputs. |

Not implemented, because the resource type does not support the underlying Azure capability:

| Interface | Reason |
| --- | --- |
| `diagnostic_settings` | Action groups emit no log or metric categories. |
| `private_endpoints` | Action groups do not support Azure Private Link. |
| `managed_identities` | The ARM schema has no `identity` property. |
| `customer_managed_key` | Action groups have no customer-managed key surface. |
| `resource_tags` | The optional per-resource tag override interface is unnecessary; there is a single taggable resource. |

## Location

Action groups are **global** resources. Set `location` to `Global` unless you specifically need a
regional action group, which Azure supports only in a small number of regions.

## `ignore_body_changes`

`ignore_body_changes` suppresses drift on specific paths in the request body, for example when
Azure Policy rewrites tags. It is a **write-only** AzAPI argument: its value is held in provider
private state and a change to it takes effect only on the next apply.

Supplying a non-empty list requires Terraform 1.11 or later. The module's Terraform floor is
deliberately left at 1.9 so that consumers who do not use the feature are not forced to upgrade.

## Retries

The module adds no unconditional retries to the action group itself; `retry` defaults to null and
is passed straight through from the consumer.

Role assignments always retry on the transient `ScopeLocked` error, which Azure raises while a
management lock on the same scope is still being removed. A lock and the role assignments on the
same action group are independent resources with no ordering between them, so without this retry a
`terraform destroy` of a locked action group fails intermittently. Patterns supplied through
`retry` are merged with `ScopeLocked` rather than replacing it.

## Importing an existing action group

```console
terraform import 'module.action_group.azapi_resource.this' '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Insights/actionGroups/<name>?api-version=2023-01-01'
```

Or, with an `import` block:

```hcl
import {
  to = module.action_group.azapi_resource.this
  id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Insights/actionGroups/<name>?api-version=2023-01-01"
}
```

After importing, declare every receiver that already exists on the action group. Any receiver you
omit is removed on the next apply.

## Known limitations

- Receiver arrays are ordered in the ARM body. The module derives that order from the Terraform
  map keys, which Terraform sorts deterministically, so the order is stable for a given
  configuration. Azure attaches no meaning to receiver order.
- Read-only receiver `status` fields are never surfaced or reconciled.
- The `region` attribute of an ITSM receiver is not constrained by the module. Azure documents a
  limited set of supported regions for ITSM connections and that list changes over time, so the
  value is passed through and validated by Azure.
- Automation webhook URIs and Logic App callback URLs are returned only by data-plane operations
  and, for Automation, only once at creation time. The module accepts them as inputs rather than
  looking them up, to avoid persisting additional credential material in state.
- Cross-subscription and cross-tenant receiver targets are supported by passing full resource IDs
  and, for event hub receivers, explicit `subscription_id` and `tenant_id` values. The module
  performs no lookups against those targets.
