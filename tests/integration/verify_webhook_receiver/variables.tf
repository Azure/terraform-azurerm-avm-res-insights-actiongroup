variable "action_group_id" {
  type        = string
  nullable    = false
  description = "The resource ID of the action group whose webhook receiver is verified."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Insights/actionGroups", var.action_group_id))
    error_message = "`action_group_id` must be a valid action group resource ID."
  }
}

variable "location" {
  type        = string
  default     = "Global"
  description = "Compatibility input for the integration test's shared location value."
}
