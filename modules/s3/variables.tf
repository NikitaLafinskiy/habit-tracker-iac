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

variable "block_public_acls" {
  type        = bool
  description = "Whether to block public ACLs for the bucket"
  default     = true
}

variable "block_public_policy" {
  type        = bool
  description = "Whether to block public bucket policies for the bucket"
  default     = true
}

variable "ignore_public_acls" {
  type        = bool
  description = "Whether to ignore public ACLs for the bucket"
  default     = true
}

variable "restrict_public_buckets" {
  type        = bool
  description = "Whether to restrict public bucket policies for the bucket"
  default     = true
}

variable "is_public" {
  type        = bool
  description = "Whether the bucket should be public (adds a public read policy and website config)"
  default     = false
}
