# Lambda-protocol subscriptions are confirmed automatically by AWS as soon as
# the subscription and matching invoke permission both exist - unlike
# http/https endpoints, there's no SubscribeURL confirmation handshake for
# the function to implement.
resource "aws_sns_topic_subscription" "this" {
  topic_arn = var.topic_arn
  protocol  = "lambda"
  endpoint  = var.lambda_alias_arn
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  qualifier     = var.lambda_alias_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.topic_arn
}
