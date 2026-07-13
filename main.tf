locals {
  name = "habit-tracker-api"
  tags = {}
}

module "api_gateway" {
  source = "./modules/api-gateway"

  name = local.name
  tags = local.tags
}

# The app's domain - registered via Route53 Domains, brought under
# management here so per-service .infra roots (e.g. auth) can source its
# zone_id for their own DNS records (e.g. SES verification/DKIM).
module "domain" {
  source = "./modules/route53"

  domain_name = var.domain_name
  tags        = local.tags

  providers = {
    aws.us_east_1 = aws.us_east_1
  }
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

