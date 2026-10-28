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

variable "alarm_email" {
  type        = string
  description = "Address the prod alarm topic emails. Required in prod; dev has no alarms."
  default     = null

  validation {
    condition     = var.environment != "prod" || var.alarm_email != null
    error_message = "alarm_email is required in prod."
  }
}

variable "monitoring_enabled" {
  type        = bool
  description = "Whether to create the dashboard, log metric filters and alarms. They watch resources the service roots create, so the first apply of a brand-new environment sets this to false, and the next apply after the services exist turns it back on."
  default     = true
}
