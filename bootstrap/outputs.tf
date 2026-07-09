output "state_bucket" {
  description = "Name of the S3 bucket to use as the Terraform S3 backend `bucket`"
  value       = aws_s3_bucket.tfstate.bucket
}

output "lock_table_name" {
  description = "Name of the DynamoDB table to use as the Terraform S3 backend `dynamodb_table`"
  value       = module.lock_table.name
}
