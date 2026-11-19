# WAF-aligned example

This example demonstrates an Azure Monitor action group configured for the applicable
[Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/) recommendations:

- **Reliability:** `Global` processing persists the action group in at least two regions.
  The action group is enabled, with email receivers for both the on-call team and service
  owner, plus a mobile push receiver for an additional notification channel.
- **Operational excellence:** email receivers use the common alert schema for consistent
  alert payloads, and tags identify the environment and scenario.
- **Safety:** a `CanNotDelete` lock protects the alert notification path from accidental
  deletion. Terraform manages the lock and removes it before destroying the action group.

See [Azure Monitor action groups](https://learn.microsoft.com/azure/azure-monitor/alerts/action-groups)
for global processing, notification methods, and common alert schema behavior. Replace the
illustrative receiver addresses with real recipients for production use; mobile push
recipients need the Azure mobile app.

All Azure resources, including the supporting resource group, use `Azure/azapi`.
No alert rule is created and no test notification is sent. This example validates deployment,
not end-to-end notification delivery.

This is a runnable E2E scenario with no required input variables or external resources.
Run `avm test e2e --example waf-aligned` from the repository root to deploy it, check
idempotency, and destroy all resources.
