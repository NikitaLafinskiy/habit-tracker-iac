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

  package_type = var.package_type
  runtime      = local.is_zip ? var.runtime : null
  handler      = local.is_zip ? var.handler : null

  s3_bucket         = local.is_zip ? var.s3_bucket : null
  s3_key            = local.is_zip ? var.s3_key : null
  s3_object_version = local.is_zip ? data.aws_s3_object.package[0].version_id : null
  image_uri         = local.is_zip ? null : "${data.aws_ecr_repository.image[0].repository_url}@${data.aws_ecr_image.image[0].image_digest}"

  memory_size = var.memory_size
  timeout     = var.timeout

  # SnapStart only applies to published versions, never to $LATEST, so every
  # deploy must publish a new version for the snapshot to be (re)created.
  publish = true

  dynamic "snap_start" {
    for_each = var.snap_start ? [1] : []
    content {
      apply_on = "PublishedVersions"
    }
  }

  environment {
    variables = merge(
      var.environment_variables,
      length(var.ssm_parameter_paths) > 0 ? {
        SSM_BACKED_PROPERTIES = join("\n", [for property_name, path in var.ssm_parameter_paths : "${property_name}=${path}"])
      } : {},
    )
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.this]
}

# Callers (API Gateway) target this alias rather than $LATEST so that every
# invocation resolves to a published, SnapStart-enabled version.
resource "aws_lambda_alias" "live" {
  name             = var.alias_name
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
}
