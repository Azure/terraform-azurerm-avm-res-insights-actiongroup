# Complete example

This example exercises the majority of the module's surface:

- multiple receiver types (email, SMS, voice, Azure mobile app push, ARM role and webhook);
- the common alert schema enabled on some receivers and left at the Azure default on others;
- tags, a `CanNotDelete` management lock and a role assignment;
- consumer-supplied `retry`, `timeouts` and `ignore_body_changes` values; and
- an aliased `azapi` provider, proving the module declares no provider configuration of its own.

All Azure resources in this example, including the supporting resource group, are created with
the `Azure/azapi` provider. The webhook endpoint is a synthetic placeholder and receives no
alert payloads.

> The role assignment requires the deploying identity to hold `Microsoft.Authorization/roleAssignments/write`
> on the target scope.
