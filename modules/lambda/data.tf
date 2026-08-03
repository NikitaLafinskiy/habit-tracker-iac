data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "lambda_execution_role_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

  dynamic "statement" {
    for_each = length(var.dynamodb_table_arns) > 0 ? [1] : []
    content {
      effect = "Allow"

      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
      ]

      # Table ARN covers base-table ops; Query/Scan against a GSI need the
      # index ARN (`…/table/NAME/index/*`) as a separate resource.
      resources = concat(
        var.dynamodb_table_arns,
        [for arn in var.dynamodb_table_arns : "${arn}/index/*"],
      )
    }
  }

  dynamic "statement" {
    for_each = length(var.ses_identity_arns) > 0 ? [1] : []
    content {
      effect = "Allow"

      actions = [
        "ses:SendEmail",
        "ses:SendRawEmail",
      ]

      resources = var.ses_identity_arns
    }
  }

  # Separate from the identity grant above - SendEmail with a
  # ConfigurationSetName also needs config-set-resource authorization (see doc/CLAUDE.md).
  dynamic "statement" {
    for_each = length(var.ses_configuration_set_arns) > 0 ? [1] : []
    content {
      effect = "Allow"

      actions = [
        "ses:SendEmail",
        "ses:SendRawEmail",
      ]

      resources = var.ses_configuration_set_arns
    }
  }

  # SQS event source mapping poller permissions - see doc/CLAUDE.md
  # "modules/lambda".
  dynamic "statement" {
    for_each = length(var.sqs_queue_arns) > 0 ? [1] : []
    content {
      effect = "Allow"

      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ChangeMessageVisibility",
      ]

      resources = var.sqs_queue_arns
    }
  }
}

data "aws_ssm_parameter" "this" {
  for_each = var.ssm_parameters

  name            = each.value
  with_decryption = true
}

# Pins the function to the current object version so Terraform actually
# sees a diff and redeploys on every CI upload to the same key (see doc/CLAUDE.md).
data "aws_s3_object" "package" {
  bucket = var.s3_bucket
  key    = var.s3_key
}
