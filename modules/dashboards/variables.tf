variable "dashboard_name" {
  type        = string
  description = "Name of the dashboard"
}

variable "aws_region" {
  type        = string
  description = "Region the services and their metrics live in"
}

variable "api_gateway_id" {
  type        = string
  description = "ID of the shared HTTP API"
}

variable "cloudfront_distribution_id" {
  type        = string
  description = "ID of the client CloudFront distribution, or null where there is none (dev)"
  default     = null
}

variable "include_ses" {
  type        = bool
  description = "Whether the environment sends email through SES (prod only)"
  default     = false
}

variable "functions" {
  type = map(object({
    name                    = string
    log_group_name          = string
    timeout_seconds         = number
    error_log_metric        = string
    database_failure_metric = string
  }))
  description = "Monitored Lambda functions, keyed by service"
}

variable "queues" {
  type = map(object({
    queue = string
    dlq   = string
  }))
  description = "SQS queues and their dead-letter queues, keyed by service"
}

variable "database_clusters" {
  type        = map(string)
  description = "Aurora DSQL cluster IDs, keyed by owning service"
}

variable "log_metric_namespace" {
  type        = string
  description = "Namespace of the metrics the log metric filters publish"
}

variable "period_seconds" {
  type        = number
  description = "Default period for every metric widget"
  default     = 300
}
