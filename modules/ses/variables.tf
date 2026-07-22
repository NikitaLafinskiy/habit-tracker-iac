variable "domain_name" {
  type        = string
  description = "Domain to verify as a SES identity (must have its hosted zone in this AWS account's Route53)"
}

variable "notification_topic_arn" {
  type        = string
  description = "SNS topic ARN to publish bounce/complaint events to via a configuration set (omit to skip event-destination setup)"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
