variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "domain_name" {
  type        = string
  description = "The app's domain, already registered via Route53 Domains"
}
