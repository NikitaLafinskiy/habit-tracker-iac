resource "aws_iam_role" "this" {
  name               = "${var.name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_policy" "this" {
  name   = "${var.name}-execution-policy"
  policy = data.aws_iam_policy_document.lambda_execution_role_policy.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_lambda_function" "this" {
  function_name = var.name
  role          = aws_iam_role.this.arn

  package_type = "Zip"
  runtime      = var.runtime
  handler      = var.handler

  s3_bucket = var.s3_bucket
  s3_key    = var.s3_key

  memory_size = var.memory_size
  timeout     = var.timeout

  # SnapStart only applies to published versions, never to $LATEST, so every
  # deploy must publish a new version for the snapshot to be (re)created.
  publish = true

  snap_start {
    apply_on = "PublishedVersions"
  }

  environment {
    variables = { for env_var_name, param in data.aws_ssm_parameter.this : env_var_name => param.value }
  }

  tags = var.tags
}

# Callers (API Gateway) target this alias rather than $LATEST so that every
# invocation resolves to a published, SnapStart-enabled version.
resource "aws_lambda_alias" "live" {
  name             = var.alias_name
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
}
