
resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = var.api_gateway_id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.lambda_invoke_arn
  integration_method = "POST"
  # StreamLambdaHandler builds its handler via getAwsProxyHandler(), which
  # deserializes the incoming event as AwsProxyRequest - the shape used by
  # REST APIs and HTTP API payload format 1.0, not the newer, differently
  # shaped 2.0 format. Mismatching this causes InvalidRequestEventException
  # ("not a valid request from Amazon API Gateway") on every call.
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
