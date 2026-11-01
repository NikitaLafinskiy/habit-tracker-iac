variable "resource_type_opt_in_preference" {
  type        = map(bool)
  description = "Every resource type AWS Backup may protect in this account and region. The resource owns the whole map: a type left out is reset, so list them all."
}

variable "resource_type_management_preference" {
  type        = map(bool)
  description = "Resource types whose backups AWS Backup fully manages (its own lifecycle and encryption) instead of the service's native backups"
  default     = {}
}
