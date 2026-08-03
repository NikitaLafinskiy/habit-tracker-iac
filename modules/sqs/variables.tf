variable "name" {
  type        = string
  description = "Name of the SNS topic"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}

variable "delay_seconds" {
  type        = number
  description = "Delay seconds for the SQS queue"
  default     = 0
}

variable "max_message_size" {
  type        = number
  description = "Max message size for the SQS queue"
  default     = 262144
}

variable "message_retention_seconds" {
  type        = number
  description = "Message retention seconds for the SQS queue"
  default     = 345600
}

variable "dlq_name" {
  type        = string
  description = "Name of the dead letter queue"
}

variable "redrivePermission" {
  type        = string
  description = "Redrive permission for the SQS queue"
  default     = "deny"
}

variable "receive_wait_time_seconds" {
  type        = number
  description = "Receive wait time seconds for the SQS queue"
  default     = 0
}

variable "maxReceiveCount" {
  type        = number
  description = "Max receive count for the SQS queue"
  default     = 10
}
