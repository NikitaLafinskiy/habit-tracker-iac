variable "tags" {
  type        = map(string)
  description = "Tags to apply to the DSQL resources"
  default     = {}
}

variable "deletion_protection" {
  type        = bool
  description = "Whether to enable deletion protection for the DSQL DB"
  default     = false
}
