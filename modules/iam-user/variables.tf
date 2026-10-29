variable "name" {
  type        = string
  description = "Name of the IAM user, also used for its inline policy"
}

variable "policy_statements" {
  type = list(object({
    actions   = list(string)
    resources = list(string)
    effect    = optional(string, "Allow")
  }))
  description = "Statements of the user's inline policy. The module never creates an access key, so no secret lands in Terraform state; create one by hand and store it in SSM."

  validation {
    condition     = length(var.policy_statements) > 0
    error_message = "An IAM user needs at least one policy statement."
  }
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
