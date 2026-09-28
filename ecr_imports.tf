import {
  for_each = local.is_prod ? toset([]) : toset(["api", "auth"])
  to       = module.lambda_image_repositories[each.key].aws_ecr_repository.this
  id       = "${each.key}${local.suffix}"
}

import {
  for_each = local.is_prod ? toset([]) : toset(["api", "auth"])
  to       = module.lambda_image_repositories[each.key].aws_ecr_lifecycle_policy.this
  id       = "${each.key}${local.suffix}"
}

import {
  for_each = local.is_prod ? toset([]) : toset(["api", "auth"])
  to       = module.lambda_image_repositories[each.key].aws_ecr_repository_policy.lambda_pull
  id       = "${each.key}${local.suffix}"
}
