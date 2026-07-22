variable "domain_name" {
  type        = string
  description = "Domain to verify as a SES identity (must have its hosted zone in this AWS account's Route53)"
}

variable "create_notifications" {
  type        = bool
  description = <<-EOT
    Whether to create the configuration set/event destination/topic policy
    wiring bounce+complaint events to notification_topic_arn. A separate
    flag rather than gating on `notification_topic_arn != null` directly -
    that ARN is typically a reference to a topic created in the same apply
    (e.g. module.sns.arn), so its value is "known after apply", and count
    can't be conditioned on a value that isn't known at plan time. This
    flag is a plain literal the caller controls, so it's always known.
  EOT
  default     = false
}

variable "notification_topic_arn" {
  type        = string
  description = "SNS topic ARN to publish bounce/complaint events to via a configuration set (only used when create_notifications is true)"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
