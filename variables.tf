variable "aws_region" {
  type        = string
  description = "AWS region"
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
