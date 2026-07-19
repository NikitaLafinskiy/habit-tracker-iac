variable "origin_domain_name" {
  type        = string
  description = "Domain name of the origin (S3 regional endpoint, ELB DNS, etc.)"
}

variable "origin_id" {
  type        = string
  default     = "default-origin"
  description = "Unique identifier for this origin (used in cache behavior target)"
}

variable "enable_origin_access_control" {
  type        = bool
  default     = true
  description = "Create an Origin Access Control (only for S3 origins)"
}

variable "origin_access_control_type" {
  type        = string
  default     = "s3"
  description = "Origin type for OAC ('s3' or 'mediastore')"
}

variable "comment" {
  type    = string
  default = "Managed by Terraform"
}

variable "default_root_object" {
  type    = string
  default = "index.html"
}

variable "aliases" {
  type        = list(string)
  description = "Alternate domain names (CNAMEs) this distribution should answer for - required for any custom domain to work, alongside acm_certificate_arn"
  default     = []
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of an ACM certificate (must exist in us-east-1) covering every entry in var.aliases. Leave null to serve only the default *.cloudfront.net domain"
  default     = null
}

variable "custom_error_responses" {
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number)
  }))
  description = "CloudFront custom error responses - e.g. mapping 403/404 to /index.html so an SPA's client-side routes work when requested directly"
  default     = []
}

variable "cache_allowed_methods" {
  type    = list(string)
  default = ["GET", "HEAD", "OPTIONS"]
}

variable "cache_cached_methods" {
  type    = list(string)
  default = ["GET", "HEAD"]
}

variable "viewer_protocol_policy" {
  type    = string
  default = "allow-all"
  validation {
    condition     = contains(["allow-all", "redirect-to-https", "https-only"], var.viewer_protocol_policy)
    error_message = "Must be allow-all, redirect-to-https, or https-only."
  }
}

variable "cache_min_ttl" {
  type    = number
  default = 0
}

variable "cache_default_ttl" {
  type    = number
  default = 3600
}

variable "cache_max_ttl" {
  type    = number
  default = 86400
}

variable "price_class" {
  type    = string
  default = "PriceClass_200"
}

variable "is_ipv6_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

