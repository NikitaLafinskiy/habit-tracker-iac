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

variable "package_type" {
  type        = string
  description = "Zip (a JVM deployment package in S3) or Image (a native executable in an ECR container image)"
  default     = "Zip"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "package_type must be Zip or Image."
  }
}

variable "s3_bucket" {
  type        = string
  description = "S3 bucket holding the built Lambda deployment package (shadow jar). Zip only"
  default     = null

  validation {
    condition     = var.package_type != "Zip" || var.s3_bucket != null
    error_message = "A Zip function needs s3_bucket."
  }
}

variable "s3_key" {
  type        = string
  description = "S3 key of the built Lambda deployment package (shadow jar). Zip only"
  default     = null

  validation {
    condition     = var.package_type != "Zip" || var.s3_key != null
    error_message = "A Zip function needs s3_key."
  }
}

variable "ecr_repository_name" {
  type        = string
  description = "ECR repository holding the function's container image. Image only"
  default     = null

  validation {
    condition     = var.package_type != "Image" || var.ecr_repository_name != null
    error_message = "An Image function needs ecr_repository_name."
  }
}

variable "image_tag" {
  type        = string
  description = "Mutable tag CI pushes on every build; the function pins the digest it resolves to, so each push is a Terraform diff. Image only"
  default     = "current"
}

variable "snap_start" {
  type        = bool
  description = "Enable SnapStart on published versions. Zip only: SnapStart on a custom image is a fixed per-version charge"
  default     = true
}

variable "image_snap_start" {
  type        = bool
  description = "Enable SnapStart on published versions of an Image function. Only for images built on an AWS Java base image, where SnapStart is billed as it is for a zip; a custom image pays a fixed per-version cache charge"
  default     = false
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

variable "dsql_cluster_arns" {
  type        = list(string)
  description = "ARNs of Aurora DSQL clusters the Lambda execution role may connect to"
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

variable "s3_bucket_arns" {
  type        = list(string)
  description = "ARNs of S3 buckets this function reads and writes objects in. Distinct from s3_bucket, which only locates the deployment package."
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

variable "ssm_parameter_paths" {
  type        = map(string)
  description = "Map of Spring property name (e.g. \"jwt.access-secret\") => SSM parameter path. Passed through as a single opaque SSM_BACKED_PROPERTIES environment variable (never resolved by Terraform), and the execution role is granted ssm:GetParameter/kms:Decrypt on the derived ARNs, so the application resolves each secret from Parameter Store at runtime rather than Terraform baking the plaintext into the function config or state."
  default     = {}
}

variable "environment_variables" {
  type        = map(string)
  description = "Map of plain (non-secret) Lambda environment variable name => value, injected alongside the SSM-resolved ones"
  default     = {}
}

variable "keep_warm" {
  type        = bool
  description = "When true, an EventBridge rule invokes the function's alias on an interval to keep an execution environment warm - a cheap stand-in for provisioned concurrency."
  default     = false
}

variable "keep_warm_interval_minutes" {
  type        = number
  description = "Interval, in minutes, between keep_warm pings. Ignored unless keep_warm is true."
  default     = 5

  validation {
    condition     = var.keep_warm_interval_minutes >= 1 && floor(var.keep_warm_interval_minutes) == var.keep_warm_interval_minutes
    error_message = "keep_warm_interval_minutes must be a whole number of minutes >= 1 (EventBridge rate() has a 1-minute minimum)."
  }
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
