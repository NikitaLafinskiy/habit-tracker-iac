output "api_id" {
  value = aws_apigatewayv2_api.this.id
}

output "api_name" {
  value = aws_apigatewayv2_api.this.name
}

output "execution_arn" {
  value = aws_apigatewayv2_api.this.execution_arn
}

output "api_endpoint" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

