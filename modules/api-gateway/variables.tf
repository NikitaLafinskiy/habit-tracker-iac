variable "name" {
  type        = string
  description = "Base name used for API Gateway resources"
}
variable "log_retention_days" {
  type        = number
  description = "Days CloudWatch keeps the stage's access logs"
  default     = 180
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
