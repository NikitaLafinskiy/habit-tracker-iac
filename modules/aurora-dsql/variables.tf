variable "name" {
  type        = string
  description = "Logical cluster name, applied as the Name tag (aws_dsql_cluster identifiers are AWS-generated)"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the DSQL resources"
  default     = {}
}

variable "deletion_protection_enabled" {
  type        = bool
  description = "Whether to enable deletion protection for the DSQL cluster"
  default     = false
}
