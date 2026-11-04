output "receiver_has_service_uri" {
  description = "Whether Azure returned the named webhook receiver with a nonempty service URI."
  value       = data.azapi_resource.action_group.output.receiver_has_service_uri
}
