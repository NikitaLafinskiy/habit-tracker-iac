variable "domain_name" {
  type        = string
  description = "Domain to verify as a SES identity (must have its hosted zone in this AWS account's Route53)"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
