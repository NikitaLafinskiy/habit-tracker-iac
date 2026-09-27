mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-central-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_s3_object" {
    defaults = {
      version_id = "object-version-1"
    }
  }

  mock_data "aws_ecr_repository" {
    defaults = {
      repository_url = "123456789012.dkr.ecr.eu-central-1.amazonaws.com/habit-tracker-api"
    }
  }

  mock_data "aws_ecr_image" {
    defaults = {
      image_digest = "sha256:0123456789abcdef"
    }
  }
}

run "zip_by_default_plans_exactly_as_before" {
  command = plan

  variables {
    name      = "api"
    s3_bucket = "habit-tracker-lambda-artifacts"
    s3_key    = "api/api-service.zip"
  }

  assert {
    condition     = aws_lambda_function.this.package_type == "Zip"
    error_message = "Zip must stay the default package type."
  }

  assert {
    condition     = aws_lambda_function.this.runtime == "java21"
    error_message = "A Zip function keeps its managed runtime."
  }

  assert {
    condition     = aws_lambda_function.this.s3_object_version == "object-version-1"
    error_message = "A Zip function must pin the S3 object version."
  }

  assert {
    condition     = length(aws_lambda_function.this.snap_start) == 1
    error_message = "A Zip function keeps SnapStart by default."
  }

  assert {
    condition     = aws_lambda_function.this.image_uri == null
    error_message = "A Zip function has no image."
  }
}

run "image_pins_the_digest_and_drops_zip_settings" {
  command = plan

  variables {
    name                = "api"
    package_type        = "Image"
    ecr_repository_name = "habit-tracker-api"
  }

  assert {
    condition     = aws_lambda_function.this.image_uri == "123456789012.dkr.ecr.eu-central-1.amazonaws.com/habit-tracker-api@sha256:0123456789abcdef"
    error_message = "An Image function must pin the digest the tag resolves to."
  }

  assert {
    condition     = aws_lambda_function.this.runtime == null && aws_lambda_function.this.handler == null
    error_message = "An Image function has no managed runtime or handler."
  }

  assert {
    condition     = aws_lambda_function.this.s3_bucket == null && aws_lambda_function.this.s3_key == null
    error_message = "An Image function does not read from S3."
  }

  assert {
    condition     = length(aws_lambda_function.this.snap_start) == 0
    error_message = "An Image function never gets SnapStart."
  }
}

run "image_without_a_repository_is_rejected" {
  command = plan

  variables {
    name         = "api"
    package_type = "Image"
  }

  expect_failures = [var.ecr_repository_name]
}

run "zip_without_a_package_is_rejected" {
  command = plan

  variables {
    name = "api"
  }

  expect_failures = [var.s3_bucket, var.s3_key]
}

run "unknown_package_type_is_rejected" {
  command = plan

  variables {
    name         = "api"
    package_type = "Jar"
    s3_bucket    = "habit-tracker-lambda-artifacts"
    s3_key       = "api/api-service.zip"
  }

  expect_failures = [var.package_type]
}
