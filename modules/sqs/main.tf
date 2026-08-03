resource "aws_sqs_queue" "this" {
  name                      = var.name
  delay_seconds             = var.delay_seconds
  max_message_size          = var.max_message_size
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = var.receive_wait_time_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.this_deadletter.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = var.tags
}

resource "aws_sqs_queue" "this_deadletter" {
  name = var.dlq_name

  tags = var.tags
}

# Lives on the DLQ: which source queues may redrive into it. Valid
# redrivePermission values are byQueue / allowAll / denyAll (not "deny").
resource "aws_sqs_queue_redrive_allow_policy" "this" {
  queue_url = aws_sqs_queue.this_deadletter.id

  redrive_allow_policy = jsonencode(
    var.redrive_permission == "byQueue"
    ? {
      redrivePermission = "byQueue"
      sourceQueueArns   = [aws_sqs_queue.this.arn]
    }
    : {
      redrivePermission = var.redrive_permission
    }
  )
}
