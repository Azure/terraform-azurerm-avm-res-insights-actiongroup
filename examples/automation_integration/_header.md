# Automation and integration example

This example wires the action group to two automation-oriented receiver types:

- an **Automation runbook receiver**, targeting a runbook webhook on an Azure Automation account; and
- a **Logic App receiver**, targeting a consumption Logic App workflow with an HTTP request trigger.

The Automation account and the Logic App workflow are supporting resources created with the
`Azure/azapi` provider, so the receivers reference real Azure resource IDs.

The endpoint values (`service_uri` for the Automation runbook receiver and `callback_url` for the
Logic App receiver) are **synthetic placeholders**. Both are credential-bearing URLs in a real
deployment: an Automation webhook URI embeds a token and is only returned once at creation time,
and a Logic App callback URL is a signed URL returned by the `listCallbackUrl` data-plane action.
Sourcing them dynamically would persist those credentials in Terraform state, so this example
uses non-functional `example.com` URLs instead.

Both values are marked sensitive by the module before they are sent to Azure.
