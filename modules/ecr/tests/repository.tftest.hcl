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
}

run "repository_takes_a_moving_tag_and_scans_every_push" {
  command = plan

  variables {
    name = "habit-tracker-api-dev"
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "MUTABLE"
    error_message = "CI re-pushes the fixed `current` tag, so tags must be mutable."
  }

  assert {
    condition     = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push
    error_message = "Every pushed image is scanned."
  }
}

run "lifecycle_keeps_the_newest_images" {
  command = plan

  variables {
    name             = "habit-tracker-api-dev"
    keep_last_images = 5
  }

  assert {
    condition     = jsondecode(aws_ecr_lifecycle_policy.this.policy).rules[0].selection.countNumber == 5
    error_message = "The lifecycle policy keeps exactly keep_last_images images."
  }
}

run "keeping_no_images_is_rejected" {
  command = plan

  variables {
    name             = "habit-tracker-api-dev"
    keep_last_images = 0
  }

  expect_failures = [var.keep_last_images]
}
