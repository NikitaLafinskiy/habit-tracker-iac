locals {
  name = "habit-tracker-api"
  tags = {}
}

module "api_gateway" {
  source = "./modules/api-gateway"

  name = local.name
  tags = local.tags
}

# Shared across all services - each service's own root uploads its build to
# a service-specific key within this bucket (e.g. "auth/auth-service.jar")
# rather than getting a bucket of its own.
module "lambda_artifacts_bucket" {
  source = "./modules/s3"

  name               = "habit-tracker-lambda-artifacts"
  versioning_enabled = true
  tags               = local.tags
}

