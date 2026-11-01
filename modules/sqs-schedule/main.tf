data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "send_message" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [var.queue_arn]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.name}-send-message"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.send_message.json
}

resource "aws_scheduler_schedule" "this" {
  name                         = var.name
  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_expression_timezone

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = var.queue_arn
    role_arn = aws_iam_role.this.arn
    input    = var.message_body
  }
}
