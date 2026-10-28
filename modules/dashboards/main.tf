resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.dashboard_name
  dashboard_body = jsonencode({
    widgets = concat(
      local.api_widgets,
      local.cloudfront_widgets,
      local.lambda_widgets,
      local.log_widgets,
      local.queue_widgets,
      local.database_widgets,
      local.ses_widgets,
    )
  })
}
