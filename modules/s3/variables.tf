variable "name" {
  type        = string
  description = "Globally-unique name for the S3 bucket"
}

variable "versioning_enabled" {
  type        = bool
  description = "Whether to enable object versioning on the bucket"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
