variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "environment" {
  type        = string
  description = <<EOF
Deployment environment. Drives the resource name suffix ("" for prod, "-dev"
for dev) and must match the backend.<env>.hcl this root was initialised with.
Has no default on purpose: a var file is
mandatory, so an apply that forgets -var-file fails instead of silently
picking one.
EOF

  validation {
    condition     = contains(["prod", "dev"], var.environment)
    error_message = "environment must be either \"prod\" or \"dev\"."
  }
}

variable "domain_name" {
  type        = string
  description = "The app's domain, already registered via Route53 Domains. Prod only - dev is backend-only and has no domain, CDN or client bucket."
  default     = null
}
