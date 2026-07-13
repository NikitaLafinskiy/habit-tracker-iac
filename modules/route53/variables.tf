variable "domain_name" {
  type        = string
  description = "Domain name already registered via Route53 Domains, to bring under Terraform management"
}

variable "auto_renew" {
  type        = bool
  description = "Whether the domain registration auto-renews"
  default     = true
}

variable "transfer_lock" {
  type        = bool
  description = "Whether to lock the domain against transfers - only enable if the TLD's registry actually supports toggling this via Route53 Domains"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
