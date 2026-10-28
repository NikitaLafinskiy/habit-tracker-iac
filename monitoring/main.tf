resource "aws_cloudwatch_log_metric_filter" "error_lines" {
  for_each = local.monitored_functions

  name           = "${each.value.name}-error-lines"
  log_group_name = each.value.log_group_name
  pattern        = local.error_log_pattern

  metric_transformation {
    name          = each.value.error_log_metric
    namespace     = local.log_metric_namespace
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "database_failure_lines" {
  for_each = { for key, function in local.monitored_functions : key => function if function.database_failure_metric != null }

  name           = "${each.value.name}-database-failure-lines"
  log_group_name = each.value.log_group_name
  pattern        = local.database_failure_pattern

  metric_transformation {
    name          = each.value.database_failure_metric
    namespace     = local.log_metric_namespace
    value         = "1"
    default_value = "0"
  }
}

module "alarm_topic" {
  source = "../modules/sns"
  count  = local.is_prod ? 1 : 0

  name = "${local.name}-alarms"
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count = local.is_prod ? 1 : 0

  topic_arn = module.alarm_topic[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

module "dashboards" {
  source = "../modules/dashboards"

  dashboard_name             = local.name
  aws_region                 = var.aws_region
  api_gateway_id             = var.api_gateway_id
  cloudfront_distribution_id = var.cloudfront_distribution_id
  include_ses                = local.is_prod
  functions                  = local.monitored_functions
  queues                     = local.queues
  database_clusters          = local.database_clusters
  log_metric_namespace       = local.log_metric_namespace

  depends_on = [
    aws_cloudwatch_log_metric_filter.error_lines,
    aws_cloudwatch_log_metric_filter.database_failure_lines,
  ]
}

module "alerts" {
  source = "../modules/alerts"
  count  = local.is_prod ? 1 : 0

  name_prefix          = local.name
  alarm_topic_arn      = module.alarm_topic[0].arn
  api_gateway_id       = var.api_gateway_id
  functions            = local.monitored_functions
  queues               = local.queues
  log_metric_namespace = local.log_metric_namespace

  depends_on = [
    aws_cloudwatch_log_metric_filter.error_lines,
    aws_cloudwatch_log_metric_filter.database_failure_lines,
  ]
}
