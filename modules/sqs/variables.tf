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

variable "receive_wait_time_seconds" {
  type        = number
  description = "Receive wait time seconds for the SQS queue"
  default     = 0
}

variable "visibility_timeout_seconds" {
  type        = number
  description = <<-EOT
    How long a received message stays hidden from other receives. AWS's guidance
    for a Lambda event source mapping is at least 6x the function timeout; the
    lambda module's default is 29s, so 180 covers it. The SQS default of 30s
    does not: a batch that runs the function to its limit can have its messages
    become visible again mid-flight and be delivered a second time.
  EOT
  default     = 180
}

variable "max_receive_count" {
  type        = number
  description = "Max receive count before a message is moved to the DLQ"
  default     = 10
}
