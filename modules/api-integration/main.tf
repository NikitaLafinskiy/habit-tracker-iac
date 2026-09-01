
resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = var.api_gateway_id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.lambda_invoke_arn
  integration_method = "POST"
  # Must stay 1.0 - StreamLambdaHandler expects the AwsProxyRequest shape,
  # not the differently-shaped 2.0 payload format.
  payload_format_version = "1.0"
}


resource "aws_apigatewayv2_route" "all" {
  for_each = { for idx, r in var.routes : "${r.method} ${r.path}" => r }

  api_id    = var.api_gateway_id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  qualifier     = var.lambda_alias_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}
