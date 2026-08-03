resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn = var.sqs_arn
  function_name    = var.lambda_arn
  batch_size       = var.batch_size

  scaling_config {
    maximum_concurrency = var.maximum_concurrency
  }
}
