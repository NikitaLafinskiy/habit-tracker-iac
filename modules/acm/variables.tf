variable "domain_name" {
  type        = string
  description = "Domain name to issue the certificate for"
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "Additional domain names to cover on the same certificate (e.g. a www subdomain)"
  default     = []
}

variable "zone_id" {
  type        = string
  description = "Route53 hosted zone ID to create the DNS validation records in"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
