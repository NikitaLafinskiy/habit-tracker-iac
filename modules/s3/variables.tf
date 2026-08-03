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

variable "expiration_days" {
  type        = number
  description = "Delete objects this many days after creation. null (the default) creates no lifecycle configuration at all, which is what build-artifact buckets want."
  default     = null
}

variable "expiration_prefix" {
  type        = string
  description = "Key prefix the expiry applies to. Empty (the default) means the whole bucket; set it when the bucket also holds objects that must not age out."
  default     = ""
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "How long a noncurrent version survives once expiration_days applies. Only meaningful on a versioned bucket, where plain expiration does not delete anything on its own."
  default     = 1
}

variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Days before an unfinished multipart upload's orphaned parts are aborted. Only applied when expiration_days is set."
  default     = 7
}

variable "is_public" {
  type        = bool
  description = "Whether the bucket should be public (adds a public read policy and website config)"
  default     = false
}
