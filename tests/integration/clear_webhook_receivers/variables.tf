variable "action_group_id" {
  type        = string
  nullable    = false
  description = "The resource ID of the action group whose webhook receiver list will be cleared out-of-band."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Insights/actionGroups", var.action_group_id))
    error_message = "`action_group_id` must be a valid action group resource ID."
  }
}
