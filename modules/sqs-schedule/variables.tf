variable "name" {
  type        = string
  description = "Name of the schedule, also the prefix of its IAM role and policy"
}

variable "queue_arn" {
  type        = string
  description = "ARN of the SQS queue the schedule sends its message to"
}

variable "schedule_expression" {
  type        = string
  description = "EventBridge Scheduler expression, e.g. cron(0 3 ? * MON *) or rate(7 days)"
}

variable "schedule_expression_timezone" {
  type        = string
  description = "Timezone the schedule expression is evaluated in"
  default     = "UTC"
}

variable "message_body" {
  type        = string
  description = "Body of the SQS message sent on every run, delivered verbatim"
}

variable "state" {
  type        = string
  description = "ENABLED or DISABLED; a disabled schedule sends nothing until it is switched on"
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.state)
    error_message = "state must be ENABLED or DISABLED."
  }
}

variable "tags" {
  type        = map(string)
  description = "Map of tags for the IAM role; Scheduler schedules take no tags"
  default     = {}
}
