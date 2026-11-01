variable "name" {
  type        = string
  description = "Name of the backup vault, plan and selection, also the prefix of the IAM role"
}

variable "resource_arns" {
  type        = list(string)
  description = "ARNs of the resources the plan backs up, e.g. a DSQL cluster"
}

variable "schedule_expression" {
  type        = string
  description = "When the daily backup runs, as an AWS Backup cron expression"
  default     = "cron(0 3 * * ? *)"
}

variable "schedule_expression_timezone" {
  type        = string
  description = "Timezone the schedule expression is evaluated in"
  default     = "UTC"
}

variable "retention_days" {
  type        = number
  description = "Days each backup is kept before AWS Backup deletes it; with one backup a day this is also how many are kept"
  default     = 14

  validation {
    condition     = var.retention_days >= 1
    error_message = "retention_days must be at least 1."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags for the vault, plan and IAM role"
  default     = {}
}
