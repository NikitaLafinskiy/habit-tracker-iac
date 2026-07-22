variable "name" {
  type        = string
  description = "Name of the SNS topic"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
