variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

variable "access_key" {
  type        = string
  description = "AWS access key"
  sensitive   = true
}

variable "secret_key" {
  type        = string
  description = "AWS secret key"
  sensitive   = true
}

variable "state_bucket_name" {
  type        = string
  description = "Globally-unique name for the Terraform remote state bucket"
  default     = "habit-tracker-terraform-state"
}

variable "lock_table_name" {
  type        = string
  description = "Name of the DynamoDB table used for Terraform state locking"
  default     = "tflock"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
