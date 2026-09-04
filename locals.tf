locals {
  # `Microsoft.Authorization/roleAssignments` races with the removal of a management lock on the
  # same scope, which surfaces as a `ScopeLocked` error for a short period after the lock is
  # deleted. This module default is replaced wholesale when the consumer supplies `var.retry`.
  role_assignment_retry_default = {
    error_message_regex  = ["ScopeLocked"]
    interval_seconds     = 15
    max_interval_seconds = 60
  }
  role_assignment_timeouts_default = {
    create = null
    read   = null
    update = null
    delete = "5m"
  }
}
