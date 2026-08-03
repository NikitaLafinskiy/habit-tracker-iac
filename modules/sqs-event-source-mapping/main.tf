resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn = var.sqs_arn
  function_name    = var.lambda_arn
  batch_size       = var.batch_size

  # Hardcoded rather than a variable, and deliberately: the Java handler
  # (SqsEventStrategy, FailureContract.PARTIAL_BATCH) always answers with a
  # batchItemFailures list. Without this the mapping ignores that response and
  # deletes the whole batch, so a failed message is dropped with no error
  # anywhere - it never reaches the queue's redrive policy or the DLQ. A
  # variable defaulting to off would make that silent data loss opt-out.
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.maximum_concurrency
  }
}
