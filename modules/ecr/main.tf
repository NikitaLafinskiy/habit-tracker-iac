data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the newest ${var.keep_last_images} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.keep_last_images
        }
        action = {
          type = "expire"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "lambda_pull" {
  statement {
    sid    = "LambdaPull"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:sourceArn"
      values   = ["arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:*"]
    }
  }
}

resource "aws_ecr_repository_policy" "lambda_pull" {
  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.lambda_pull.json
}
