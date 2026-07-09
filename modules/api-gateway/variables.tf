variable "name" {
  type        = string
  description = "Base name used for API Gateway resources"
}
variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
