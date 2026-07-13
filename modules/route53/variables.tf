variable "domain_name" {
  type        = string
  description = "Domain name already registered via Route53 Domains, to bring under Terraform management"
}

variable "auto_renew" {
  type        = bool
  description = "Whether the domain registration auto-renews"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
