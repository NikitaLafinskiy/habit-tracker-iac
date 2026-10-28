variable "name_prefix" {
  type        = string
  description = "Prefix for every alarm name"
}

variable "alarm_topic_arn" {
  type        = string
  description = "SNS topic every alarm notifies on ALARM and on OK"
}

variable "api_gateway_id" {
  type        = string
  description = "ID of the shared HTTP API"
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

variable "log_metric_namespace" {
  type        = string
  description = "Namespace of the metrics the log metric filters publish"
}

variable "period_seconds" {
  type        = number
  description = "Evaluation period shared by every alarm"
  default     = 300
}

variable "lambda_error_threshold" {
  type        = number
  description = "Failed invocations plus ERROR log lines per period that raise a function's error alarm"
  default     = 1
}

variable "api_5xx_threshold" {
  type        = number
  description = "API Gateway 5xx responses per period that raise the 5xx alarm"
  default     = 5
}

variable "api_latency_p95_ms" {
  type        = number
  description = "API Gateway p95 latency, in milliseconds, that raises the latency alarm when exceeded for three periods in a row"
  default     = 3000
}

variable "ses_bounce_rate_threshold" {
  type        = number
  description = "SES reputation bounce rate (a fraction) that raises the alarm, set below the 5% at which AWS reviews the account"
  default     = 0.04
}

variable "ses_complaint_rate_threshold" {
  type        = number
  description = "SES reputation complaint rate (a fraction) that raises the alarm, set below the 0.1% at which AWS reviews the account"
  default     = 0.0008
}

variable "database_failure_threshold" {
  type        = number
  description = "Database exception log lines per period that count as a spike"
  default     = 5
}
