variable "sqs_arn" {
  type        = string
  description = "SQS ARN to map events from"
}

variable "lambda_arn" {
  type        = string
  description = "Lambda ARN to invoke"
}

variable "batch_size" {
  type        = number
  description = "Batch size for event source mapping"
  default     = 10
}

variable "maximum_concurrency" {
  type        = number
  description = "Maximum concurrency for event source mapping"
  default     = 10
}

