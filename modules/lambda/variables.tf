variable "name" {
  type        = string
  description = "Base name used for the Lambda function and related resources"
}

variable "runtime" {
  type        = string
  description = "Lambda Java managed runtime to use (must support SnapStart)"
  default     = "java21"
}

variable "handler" {
  type        = string
  description = "Fully-qualified Lambda handler method"
  default     = "com.auth.authservice.lambda.StreamLambdaHandler::handleRequest"
}

variable "s3_bucket" {
  type        = string
  description = "S3 bucket holding the built Lambda deployment package (shadow jar)"
}

variable "s3_key" {
  type        = string
  description = "S3 key of the built Lambda deployment package (shadow jar)"
}

variable "alias_name" {
  type        = string
  description = "Name of the Lambda alias that always points at the latest published (SnapStart-enabled) version"
  default     = "live"
}

variable "memory_size" {
  type        = number
  description = "Lambda memory size in MB"
  default     = 1024
}

variable "timeout" {
  type        = number
  description = "Lambda timeout in seconds"
  default     = 29
}

variable "dynamodb_table_arns" {
  type        = list(string)
  description = "ARNs of DynamoDB tables the Lambda execution role may access"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
