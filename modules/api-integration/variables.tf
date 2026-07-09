variable "api_gateway_id" {
  type        = string
  description = "ID of the API Gateway"
}

variable "api_gateway_execution_arn" {
  type        = string
  description = "Execution ARN of the API Gateway"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function to invoke"
}

variable "lambda_invoke_arn" {
  type        = string
  description = "Invoke ARN of the Lambda function"
}

variable "lambda_alias_name" {
  type        = string
  description = "Name of the Lambda alias (qualifier) that permission to invoke is scoped to"
}

variable "routes" {
  type = list(object({
    path   = string
    method = string
  }))
  description = "API Gateway route configurations (fmt: method = 'ANY', path = '/api/auth/{proxy+}'"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}
