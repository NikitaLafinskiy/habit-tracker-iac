# Optional EventBridge-driven warmup. Cheap alternative to provisioned
# concurrency: a scheduled rule invokes the function on an interval so an
# execution environment stays live instead of cold-starting. See doc/CLAUDE.md
# "modules/lambda (keep_warm)" for why this targets the alias and relies on the
# standard scheduled-event shape rather than a custom input.
resource "aws_cloudwatch_event_rule" "keep_warm" {
  count = var.keep_warm ? 1 : 0

  name                = "${var.name}-keep-warm"
  description         = "Periodic warmup ping for ${var.name} (avoids cold starts without paid provisioned concurrency)"
  schedule_expression = "rate(${var.keep_warm_interval_minutes} ${var.keep_warm_interval_minutes == 1 ? "minute" : "minutes"})"
  tags                = var.tags
}

# Targets the alias, not $LATEST: the warm environments that matter are the
# published, SnapStart-restored ones that real traffic resolves to through the
# alias (same as api-gateway/sqs). Pinging $LATEST would keep a different,
# never-served environment warm.
resource "aws_cloudwatch_event_target" "keep_warm" {
  count = var.keep_warm ? 1 : 0

  rule      = aws_cloudwatch_event_rule.keep_warm[0].name
  target_id = "${var.name}-keep-warm"
  arn       = aws_lambda_alias.live.arn

  # No input override: EventBridge delivers its standard scheduled-event payload
  # (source "aws.events", detail-type "Scheduled Event"), which the services'
  # KeepWarmEventStrategy already recognises. This is the only scheduled rule on
  # the function, so that shape unambiguously means "warmup". See doc/CLAUDE.md.
}

# Permission is scoped to the alias (qualifier), matching the target above.
resource "aws_lambda_permission" "keep_warm" {
  count = var.keep_warm ? 1 : 0

  statement_id  = "AllowEventBridgeKeepWarm"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  qualifier     = aws_lambda_alias.live.name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.keep_warm[0].arn
}
