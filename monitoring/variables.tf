variable "environment" {
  type        = string
  description = "Deployment environment. Selects the monitored resource names (\"\" suffix for prod, \"-dev\" for dev) and whether alarms exist (prod only)."

  validation {
    condition     = contains(["prod", "dev"], var.environment)
    error_message = "environment must be either \"prod\" or \"dev\"."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region the services and their metrics live in"
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

variable "alarm_email" {
  type        = string
  description = "Address the alarm topic emails. Required in prod; dev gets dashboards and no alarms."
  default     = null
}
