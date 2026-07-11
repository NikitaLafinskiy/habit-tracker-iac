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
}

data "aws_ssm_parameter" "this" {
  for_each = {
    jwt_access_secret  = "/services/auth/jwt/access-secret"
    jwt_refresh_secret = "/services/auth/jwt/refresh-secret"
  }
  name            = each.value
  with_decryption = true
}
