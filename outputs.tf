output "name" {
  description = "The name of the action group."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "The resource ID of the action group."
  value       = azapi_resource.this.id
}

output "role_assignment_resource_ids" {
  description = "A map of role assignment resource IDs, keyed by the `role_assignments` map key."
  value       = { for k, v in azapi_resource.role_assignments : k => v.id }
}
