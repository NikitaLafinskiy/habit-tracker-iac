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

output "lambda_artifacts_bucket" {
  description = "Name of the shared S3 bucket that holds Lambda deployment artifacts for all services"
  value       = module.lambda_artifacts_bucket.name
}

output "domain_zone_id" {
  description = "Route53 hosted zone ID for the app's registered domain"
  value       = module.domain.zone_id
}

output "files_artifacts_bucket" {
  description = "Name of the bucket holding user-uploaded files (CSV imports under csv-metrics/)"
  value       = module.files_artifacts_bucket.name
}

output "files_artifacts_bucket_arn" {
  description = "ARN of the user-uploaded files bucket, for granting a service access to it"
  value       = module.files_artifacts_bucket.arn
}
