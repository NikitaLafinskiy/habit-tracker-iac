locals {
  suffix  = var.environment == "prod" ? "" : "-${var.environment}"
  is_prod = var.environment == "prod"
  name    = "habit-tracker-api${local.suffix}"
  tags    = {}
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
  count  = local.is_prod ? 1 : 0

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

  name               = "habit-tracker-lambda-artifacts${local.suffix}"
  versioning_enabled = true
  tags               = local.tags
}

# Bucket for the client-side artifacts (e.g. React build), served via
# CloudFront. Not public - OAC below is the only intended read path.
module "client_artifacts_bucket" {
  source = "./modules/s3"
  count  = local.is_prod ? 1 : 0

  name               = "habit-tracker-client-artifacts"
  versioning_enabled = true
  tags               = local.tags
}

# Bucket for files uploaded by users. The CSVs the api stages for the SQS
# file-processor pipeline live under csv-metrics/ and expire after 4 days -
# the queue consumes them in minutes, and the rest is slack for a DLQ redrive.
# Scoped to that prefix so anything else stored here later doesn't inherit it.
module "files_artifacts_bucket" {
  source = "./modules/s3"

  name               = "habit-tracker-files-artifacts${local.suffix}"
  versioning_enabled = true
  expiration_days    = 4
  expiration_prefix  = "csv-metrics/"
  tags               = local.tags
}

# CloudFront needs its certificate in us-east-1 regardless of var.aws_region.
module "client_certificate" {
  source = "./modules/acm"
  count  = local.is_prod ? 1 : 0

  domain_name = var.domain_name
  zone_id     = module.domain[0].zone_id
  tags        = local.tags

  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}

module "cloudfront" {
  source = "./modules/cloudfront"
  count  = local.is_prod ? 1 : 0

  origin_domain_name = module.client_artifacts_bucket[0].regional_domain_name

  comment             = "Habit tracker client SPA"
  default_root_object = "index.html"

  enable_origin_access_control = true
  origin_access_control_type   = "s3"

  aliases             = [var.domain_name]
  acm_certificate_arn = module.client_certificate[0].certificate_arn

  # Client-side routes (e.g. /metrics/create) have no matching S3 key, so
  # OAC-fetched requests for them come back 403/404 from the origin -
  # rewrite both to index.html so the SPA's own router can take over.
  custom_error_responses = [
    { error_code = 403, response_code = 200, response_page_path = "/index.html" },
    { error_code = 404, response_code = 200, response_page_path = "/index.html" },
  ]

  tags = local.tags
}

# Scopes bucket access to this CloudFront distribution via OAC. PutObject
# grant is intentional despite CloudFront being read-only.
data "aws_iam_policy_document" "client_artifacts_cloudfront_access" {
  count = local.is_prod ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${module.client_artifacts_bucket[0].arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront[0].distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "client_artifacts_cloudfront_access" {
  count = local.is_prod ? 1 : 0

  bucket = module.client_artifacts_bucket[0].id
  policy = data.aws_iam_policy_document.client_artifacts_cloudfront_access[0].json
}

# Create a Route53 record for the CloudFront distribution, so the app can be accessed via its domain name
resource "aws_route53_record" "cloudfront" {
  count = local.is_prod ? 1 : 0

  zone_id = module.domain[0].zone_id
  name    = module.domain[0].domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront[0].domain_name
    zone_id                = module.cloudfront[0].hosted_zone_id
    evaluate_target_health = false
  }
}
