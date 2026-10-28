locals {
  actions = [var.alarm_topic_arn]

  database_functions = {
    for key, function in var.functions : key => function if function.database_failure_metric != null
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = var.functions

  alarm_name          = "${var.name_prefix}-${each.value.name}-errors"
  alarm_description   = "${each.value.name} failed invocations plus ERROR log lines. Open ${each.value.log_group_name} and filter on \"ERROR [\"."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = var.lambda_error_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.actions
  ok_actions          = local.actions

  metric_query {
    id          = "errors"
    expression  = "FILL(invocation_errors, 0) + FILL(error_lines, 0)"
    label       = "Errors"
    return_data = true
  }

  metric_query {
    id = "invocation_errors"

    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Errors"
      period      = var.period_seconds
      stat        = "Sum"
      dimensions  = { FunctionName = each.value.name }
    }
  }

  metric_query {
    id = "error_lines"

    metric {
      namespace   = var.log_metric_namespace
      metric_name = each.value.error_log_metric
      period      = var.period_seconds
      stat        = "Sum"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each = var.functions

  alarm_name          = "${var.name_prefix}-${each.value.name}-throttles"
  alarm_description   = "${each.value.name} invocations were throttled."
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  dimensions          = { FunctionName = each.value.name }
  statistic           = "Sum"
  period              = var.period_seconds
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.actions
  ok_actions          = local.actions
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${var.name_prefix}-api-gateway-5xx"
  alarm_description   = "API Gateway returned 5xx responses. The failing routes are in the dashboard's \"Failing requests by route\" table."
  namespace           = "AWS/ApiGateway"
  metric_name         = "5xx"
  dimensions          = { ApiId = var.api_gateway_id }
  statistic           = "Sum"
  period              = var.period_seconds
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.api_5xx_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.actions
  ok_actions          = local.actions
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.name_prefix}-api-gateway-latency"
  alarm_description   = "API Gateway p95 latency stayed above ${var.api_latency_p95_ms} ms for three periods in a row."
  namespace           = "AWS/ApiGateway"
  metric_name         = "Latency"
  dimensions          = { ApiId = var.api_gateway_id }
  extended_statistic  = "p95"
  period              = var.period_seconds
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.api_latency_p95_ms
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.actions
  ok_actions          = local.actions
}

resource "aws_cloudwatch_metric_alarm" "ses_bounce_rate" {
  alarm_name          = "${var.name_prefix}-ses-bounce-rate"
  alarm_description   = "SES bounce rate is close to the 5% at which AWS puts sending under review."
  namespace           = "AWS/SES"
  metric_name         = "Reputation.BounceRate"
  statistic           = "Maximum"
  period              = var.period_seconds
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.ses_bounce_rate_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.actions
  ok_actions          = local.actions
}

resource "aws_cloudwatch_metric_alarm" "ses_complaint_rate" {
  alarm_name          = "${var.name_prefix}-ses-complaint-rate"
  alarm_description   = "SES complaint rate is close to the 0.1% at which AWS puts sending under review."
  namespace           = "AWS/SES"
  metric_name         = "Reputation.ComplaintRate"
  statistic           = "Maximum"
  period              = var.period_seconds
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.ses_complaint_rate_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.actions
  ok_actions          = local.actions
}

resource "aws_cloudwatch_metric_alarm" "dead_letter_messages" {
  for_each = var.queues

  alarm_name          = "${var.name_prefix}-${each.value.dlq}-messages"
  alarm_description   = "Messages reached ${each.value.dlq}: work from ${each.value.queue} failed every retry. It returns to OK once the queue is redriven or purged."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = each.value.dlq }
  statistic           = "Maximum"
  period              = var.period_seconds
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.actions
  ok_actions          = local.actions
}

resource "aws_cloudwatch_metric_alarm" "database_failures" {
  for_each = local.database_functions

  alarm_name          = "${var.name_prefix}-${each.value.name}-database-failures"
  alarm_description   = "Spike in database exception lines in ${each.value.log_group_name}."
  namespace           = var.log_metric_namespace
  metric_name         = each.value.database_failure_metric
  statistic           = "Sum"
  period              = var.period_seconds
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.database_failure_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.actions
  ok_actions          = local.actions
}
