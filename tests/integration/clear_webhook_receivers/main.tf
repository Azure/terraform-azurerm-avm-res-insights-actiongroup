resource "azapi_update_resource" "action_group" {
  type        = "Microsoft.Insights/actionGroups@2023-01-01"
  resource_id = var.action_group_id

  body = {
    properties = {
      webhookReceivers = []
    }
  }

  response_export_values = {
    webhook_receiver_count = "length(properties.webhookReceivers)"
  }
}
