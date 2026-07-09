output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "function_arn" {
  value = aws_lambda_function.this.arn
}

output "alias_name" {
  value = aws_lambda_alias.live.name
}

output "invoke_arn" {
  description = "Invoke ARN of the alias, so invocations resolve to the published SnapStart version"
  value       = aws_lambda_alias.live.invoke_arn
}

output "alias_arn" {
  value = aws_lambda_alias.live.arn
}

output "published_version" {
  value = aws_lambda_function.this.version
}
