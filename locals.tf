locals {
  # Deleting a `Microsoft.Authorization/roleAssignments` races with the removal of a management
  # lock on the same scope, which Azure reports as `ScopeLocked`. The pattern is merged into any
  # consumer-supplied retry rather than replacing it, because losing it makes destroy racy.
  role_assignment_retry = {
    error_message_regex  = distinct(concat(var.retry == null ? [] : coalesce(var.retry.error_message_regex, []), ["ScopeLocked"]))
    interval_seconds     = var.retry == null ? 15 : coalesce(var.retry.interval_seconds, 15)
    max_interval_seconds = var.retry == null ? 60 : coalesce(var.retry.max_interval_seconds, 60)
  }
  role_assignment_timeouts_default = {
    create = null
    read   = null
    update = null
    delete = "5m"
  }
}
