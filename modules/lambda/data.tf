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

      resources = var.dynamodb_table_arns
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
}

data "aws_ssm_parameter" "this" {
  for_each = var.ssm_parameters

  name            = each.value
  with_decryption = true
}

# aws_lambda_function only diffs on the s3_bucket/s3_key strings, not on the
# object's actual content - since CI re-uploads to the same key on every
# build, those strings never change and Terraform would otherwise see no
# diff at all. Looking up the current object version (the bucket has
# versioning enabled) and pinning the function to it gives Terraform a
# value that actually changes on every new upload, so it redeploys.
data "aws_s3_object" "package" {
  bucket = var.s3_bucket
  key    = var.s3_key
}
