output "ops_receiver_count" {
  description = "How many webhook receivers named 'ops' Azure currently returns."
  value       = data.azapi_resource.action_group.output.ops_receiver_count
}

output "receiver_has_service_uri" {
  description = "Whether Azure returned the named webhook receiver with a nonempty service URI."
  value       = data.azapi_resource.action_group.output.receiver_has_service_uri
}

output "webhook_receiver_count" {
  description = "How many webhook receivers Azure currently returns."
  value       = data.azapi_resource.action_group.output.webhook_receiver_count
}
