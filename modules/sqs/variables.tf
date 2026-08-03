variable "name" {
  type        = string
  description = "Name of the main SQS queue"
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

variable "redrive_permission" {
  type        = string
  description = <<-EOT
    DLQ redrive allow policy permission. AWS accepts byQueue, allowAll, or
    denyAll. byQueue (the default) restricts redrive to this module's source
    queue and sets sourceQueueArns accordingly.
  EOT
  default     = "byQueue"

  validation {
    condition     = contains(["byQueue", "allowAll", "denyAll"], var.redrive_permission)
    error_message = "redrive_permission must be one of: byQueue, allowAll, denyAll."
  }
}

variable "receive_wait_time_seconds" {
  type        = number
  description = "Receive wait time seconds for the SQS queue"
  default     = 0
}

variable "max_receive_count" {
  type        = number
  description = "Max receive count before a message is moved to the DLQ"
  default     = 10
}
