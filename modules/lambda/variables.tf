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

variable "ses_identity_arns" {
  type        = list(string)
  description = "ARNs of SES identities the Lambda execution role may send email from"
  default     = []
}

variable "ses_configuration_set_arns" {
  type        = list(string)
  description = <<-EOT
    ARNs of SES configuration sets the Lambda execution role may reference
    when sending. A separate grant from ses_identity_arns above - SES
    authorizes SendEmail/SendRawEmail against the sending identity AND
    (when ConfigurationSetName is set) the configuration set as two
    distinct resources, so both need their own Allow statement.
  EOT
  default     = []
}

variable "sqs_queue_arns" {
  type        = list(string)
  description = <<-EOT
    ARNs of SQS queues the Lambda execution role may poll (event source
    mapping). Grants the ReceiveMessage/DeleteMessage/GetQueueAttributes/
    ChangeMessageVisibility set AWS requires for an SQS trigger.
  EOT
  default     = []
}

variable "ssm_parameters" {
  type        = map(string)
  description = "Map of Lambda environment variable name => SSM parameter name to resolve at plan/apply time and inject as that environment variable"
  default     = {}
}

variable "environment_variables" {
  type        = map(string)
  description = "Map of plain (non-secret) Lambda environment variable name => value, injected alongside the SSM-resolved ones"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
