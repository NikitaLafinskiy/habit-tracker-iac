variable "topic_arn" {
  type        = string
  description = "ARN of the SNS topic to subscribe the Lambda function to"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function to invoke for each topic message"
}

variable "lambda_alias_name" {
  type        = string
  description = "Name of the Lambda alias SNS is permitted to invoke"
}

variable "lambda_alias_arn" {
  type        = string
  description = "ARN of the Lambda alias to subscribe (invocations resolve to this alias, not $LATEST)"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
