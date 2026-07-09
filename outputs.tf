output "api_gateway_id" {
  description = "ID of the shared API Gateway"
  value       = module.api_gateway.api_id
}

output "api_gateway_name" {
  description = "Name of the shared API Gateway"
  value       = module.api_gateway.api_name
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the shared API Gateway"
  value       = module.api_gateway.execution_arn
}

output "api_gateway_endpoint" {
  description = "Invoke URL of the shared API Gateway's $default stage"
  value       = module.api_gateway.api_endpoint
}
