output "webhook_receiver_count" {
  description = "The number of webhook receivers Azure returned after clearing the list."
  value       = azapi_update_resource.action_group.output.webhook_receiver_count
}
