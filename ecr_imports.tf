data "aws_ecr_repositories" "existing" {}

import {
  for_each = local.existing_lambda_image_repositories
  to       = module.lambda_image_repositories[each.key].aws_ecr_repository.this
  id       = each.value
}

import {
  for_each = local.existing_lambda_image_repositories
  to       = module.lambda_image_repositories[each.key].aws_ecr_lifecycle_policy.this
  id       = each.value
}

import {
  for_each = local.existing_lambda_image_repositories
  to       = module.lambda_image_repositories[each.key].aws_ecr_repository_policy.lambda_pull
  id       = each.value
}
