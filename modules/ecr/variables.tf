variable "name" {
  type        = string
  description = "Name of the ECR repository"
}

variable "keep_last_images" {
  type        = number
  description = "How many of the newest images the lifecycle policy keeps; older ones expire"
  default     = 10

  validation {
    condition     = var.keep_last_images >= 1
    error_message = "keep_last_images must keep at least the image the function runs."
  }
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
