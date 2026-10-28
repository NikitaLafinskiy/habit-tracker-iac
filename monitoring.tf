module "monitoring" {
  source = "./monitoring"
  count  = var.monitoring_enabled ? 1 : 0

  environment                = var.environment
  aws_region                 = var.aws_region
  api_gateway_id             = module.api_gateway.api_id
  cloudfront_distribution_id = local.is_prod ? element(split("/", module.cloudfront[0].distribution_arn), 1) : null
  alarm_email                = var.alarm_email
}
