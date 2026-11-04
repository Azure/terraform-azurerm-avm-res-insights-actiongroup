data "azapi_resource" "action_group" {
  type        = "Microsoft.Insights/actionGroups@2023-01-01"
  resource_id = var.action_group_id

  response_export_values = {
    receiver_has_service_uri = "length(properties.webhookReceivers[?name == 'ops' && serviceUri != `null` && serviceUri != '']) > `0`"
  }
}
