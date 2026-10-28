locals {
  database_functions = {
    for key, function in var.functions : key => function if function.database_failure_metric != null
  }

  sources = join(" | ", [for function in var.functions : "SOURCE '${function.log_group_name}'"])

  request_line = "/(?<method>GET|POST|PUT|PATCH|DELETE|OPTIONS|HEAD) (?<path>\\S+) -> (?<status>\\d{3}) \\((?<ms>\\d+) ms\\)/"

  api_widgets = [
    {
      type       = "text"
      width      = 24
      height     = 1
      properties = { markdown = "## API Gateway (API-wide)" }
    },
    {
      type   = "metric"
      width  = 8
      height = 6
      properties = {
        title   = "Requests"
        region  = var.aws_region
        view    = "timeSeries"
        stat    = "Sum"
        period  = var.period_seconds
        metrics = [["AWS/ApiGateway", "Count", "ApiId", var.api_gateway_id, { label = "Requests" }]]
      }
    },
    {
      type   = "metric"
      width  = 8
      height = 6
      properties = {
        title  = "Status codes"
        region = var.aws_region
        view   = "timeSeries"
        stat   = "Sum"
        period = var.period_seconds
        metrics = [
          [{ expression = "FILL(requests, 0) - FILL(client_errors, 0) - FILL(server_errors, 0)", label = "2xx/3xx", id = "successes" }],
          ["AWS/ApiGateway", "Count", "ApiId", var.api_gateway_id, { id = "requests", visible = false }],
          ["AWS/ApiGateway", "4xx", "ApiId", var.api_gateway_id, { id = "client_errors", label = "4xx" }],
          ["AWS/ApiGateway", "5xx", "ApiId", var.api_gateway_id, { id = "server_errors", label = "5xx" }],
        ]
      }
    },
    {
      type   = "metric"
      width  = 8
      height = 6
      properties = {
        title  = "Latency (ms)"
        region = var.aws_region
        view   = "timeSeries"
        period = var.period_seconds
        metrics = [
          ["AWS/ApiGateway", "Latency", "ApiId", var.api_gateway_id, { stat = "p50", label = "p50" }],
          ["AWS/ApiGateway", "Latency", "ApiId", var.api_gateway_id, { stat = "p95", label = "p95" }],
          ["AWS/ApiGateway", "Latency", "ApiId", var.api_gateway_id, { stat = "p99", label = "p99" }],
          ["AWS/ApiGateway", "IntegrationLatency", "ApiId", var.api_gateway_id, { stat = "p95", label = "Integration p95" }],
        ]
      }
    },
  ]

  cloudfront_widgets = [for widget in [
    {
      type       = "text"
      width      = 24
      height     = 1
      properties = { markdown = "## CloudFront (web client)" }
    },
    {
      type   = "metric"
      width  = 12
      height = 6
      properties = {
        title   = "Requests"
        region  = "us-east-1"
        view    = "timeSeries"
        stat    = "Sum"
        period  = var.period_seconds
        metrics = [["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id, "Region", "Global", { label = "Requests" }]]
      }
    },
    {
      type   = "metric"
      width  = 12
      height = 6
      properties = {
        title  = "Error rate (%)"
        region = "us-east-1"
        view   = "timeSeries"
        stat   = "Average"
        period = var.period_seconds
        metrics = [
          ["AWS/CloudFront", "4xxErrorRate", "DistributionId", var.cloudfront_distribution_id, "Region", "Global", { label = "4xx" }],
          ["AWS/CloudFront", "5xxErrorRate", "DistributionId", var.cloudfront_distribution_id, "Region", "Global", { label = "5xx" }],
        ]
      }
    },
  ] : widget if var.cloudfront_distribution_id != null]

  lambda_widgets = concat(
    [
      {
        type       = "text"
        width      = 24
        height     = 1
        properties = { markdown = "## Lambda" }
      },
    ],
    flatten([
      for key, function in var.functions : [
        {
          type   = "metric"
          width  = 8
          height = 6
          properties = {
            title  = "${function.name}: invocations, errors, throttles"
            region = var.aws_region
            view   = "timeSeries"
            stat   = "Sum"
            period = var.period_seconds
            metrics = [
              ["AWS/Lambda", "Invocations", "FunctionName", function.name, { label = "Invocations" }],
              ["AWS/Lambda", "Errors", "FunctionName", function.name, { label = "Errors" }],
              ["AWS/Lambda", "Throttles", "FunctionName", function.name, { label = "Throttles" }],
            ]
          }
        },
        {
          type   = "metric"
          width  = 8
          height = 6
          properties = {
            title  = "${function.name}: duration vs ${function.timeout_seconds} s timeout (ms)"
            region = var.aws_region
            view   = "timeSeries"
            period = var.period_seconds
            metrics = [
              ["AWS/Lambda", "Duration", "FunctionName", function.name, { stat = "p95", label = "p95" }],
              ["AWS/Lambda", "Duration", "FunctionName", function.name, { stat = "Maximum", label = "Max" }],
            ]
            annotations = {
              horizontal = [{ label = "Timeout", value = function.timeout_seconds * 1000 }]
            }
          }
        },
        {
          type   = "metric"
          width  = 8
          height = 6
          properties = {
            title  = "${function.name}: concurrency and ERROR log lines"
            region = var.aws_region
            view   = "timeSeries"
            period = var.period_seconds
            metrics = [
              ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", function.name, { stat = "Maximum", label = "Concurrent executions" }],
              [var.log_metric_namespace, function.error_log_metric, { stat = "Sum", label = "ERROR log lines" }],
            ]
          }
        },
      ]
    ]),
  )

  log_widgets = [
    {
      type       = "text"
      width      = 24
      height     = 1
      properties = { markdown = "## Logs" }
    },
    {
      type   = "metric"
      width  = 8
      height = 6
      properties = {
        title  = "ERROR log lines per function"
        region = var.aws_region
        view   = "timeSeries"
        stat   = "Sum"
        period = var.period_seconds
        metrics = [
          for function in var.functions : [var.log_metric_namespace, function.error_log_metric, { label = function.name }]
        ]
      }
    },
    {
      type   = "log"
      width  = 16
      height = 6
      properties = {
        title  = "Failing requests by route (5xx)"
        region = var.aws_region
        view   = "table"
        query  = "${local.sources} | parse @message ${local.request_line} | filter status like /^5/ | stats count() as failures, max(@timestamp) as last_seen by method, path, status, @log | sort failures desc | limit 25"
      }
    },
    {
      type   = "log"
      width  = 24
      height = 8
      properties = {
        title  = "Recent ERROR log lines"
        region = var.aws_region
        view   = "table"
        query  = "${local.sources} | fields @timestamp, @log, @message | filter @message like \"ERROR [\" | sort @timestamp desc | limit 50"
      }
    },
  ]

  queue_widgets = concat(
    [
      {
        type       = "text"
        width      = 24
        height     = 1
        properties = { markdown = "## Queues" }
      },
    ],
    flatten([
      for key, queue in var.queues : [
        {
          type   = "metric"
          width  = 8
          height = 6
          properties = {
            title  = "${queue.queue}: backlog"
            region = var.aws_region
            view   = "timeSeries"
            stat   = "Maximum"
            period = var.period_seconds
            metrics = [
              ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", queue.queue, { label = "Waiting" }],
              ["AWS/SQS", "ApproximateNumberOfMessagesNotVisible", "QueueName", queue.queue, { label = "In flight" }],
            ]
          }
        },
        {
          type   = "metric"
          width  = 8
          height = 6
          properties = {
            title  = "${queue.queue}: lag (age of oldest message, s)"
            region = var.aws_region
            view   = "timeSeries"
            stat   = "Maximum"
            period = var.period_seconds
            metrics = [
              ["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", queue.queue, { label = "Oldest message age" }],
            ]
          }
        },
        {
          type   = "metric"
          width  = 8
          height = 6
          properties = {
            title  = "${queue.queue}: throughput"
            region = var.aws_region
            view   = "timeSeries"
            stat   = "Sum"
            period = var.period_seconds
            metrics = [
              ["AWS/SQS", "NumberOfMessagesSent", "QueueName", queue.queue, { label = "Sent" }],
              ["AWS/SQS", "NumberOfMessagesReceived", "QueueName", queue.queue, { label = "Received" }],
              ["AWS/SQS", "NumberOfMessagesDeleted", "QueueName", queue.queue, { label = "Deleted" }],
            ]
          }
        },
      ]
    ]),
    [
      {
        type   = "metric"
        width  = 24
        height = 6
        properties = {
          title  = "Dead-letter queues: messages waiting"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Maximum"
          period = var.period_seconds
          metrics = [
            for queue in var.queues : ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", queue.dlq, { label = queue.dlq }]
          ]
        }
      },
    ],
  )

  database_widgets = concat(
    [
      {
        type       = "text"
        width      = 24
        height     = 1
        properties = { markdown = "## Databases (Aurora DSQL). DSQL publishes no read latency: per-query timings are in X-Ray traces." }
      },
    ],
    flatten([
      for key, cluster_id in var.database_clusters : [
        {
          type   = "metric"
          width  = 8
          height = 6
          properties = {
            title  = "${key}: commit (write) latency"
            region = var.aws_region
            view   = "timeSeries"
            period = var.period_seconds
            metrics = [
              ["AWS/AuroraDSQL", "CommitLatency", "ClusterId", cluster_id, { stat = "Average", label = "Average" }],
              ["AWS/AuroraDSQL", "CommitLatency", "ClusterId", cluster_id, { stat = "Maximum", label = "Max" }],
            ]
          }
        },
        {
          type   = "metric"
          width  = 8
          height = 6
          properties = {
            title  = "${key}: transactions and write conflicts"
            region = var.aws_region
            view   = "timeSeries"
            stat   = "Sum"
            period = var.period_seconds
            metrics = [
              ["AWS/AuroraDSQL", "TotalTransactions", "ClusterId", cluster_id, { label = "All transactions" }],
              ["AWS/AuroraDSQL", "ReadOnlyTransactions", "ClusterId", cluster_id, { label = "Read-only" }],
              ["AWS/AuroraDSQL", "OccConflicts", "ClusterId", cluster_id, { label = "OCC conflicts" }],
            ]
          }
        },
        {
          type   = "metric"
          width  = 8
          height = 6
          properties = {
            title  = "${key}: usage (DPU)"
            region = var.aws_region
            view   = "timeSeries"
            stat   = "Sum"
            period = var.period_seconds
            metrics = [
              ["AWS/AuroraDSQL", "ReadDPU", "ClusterId", cluster_id, { label = "Read" }],
              ["AWS/AuroraDSQL", "WriteDPU", "ClusterId", cluster_id, { label = "Write" }],
              ["AWS/AuroraDSQL", "ComputeDPU", "ClusterId", cluster_id, { label = "Compute" }],
            ]
          }
        },
      ]
    ]),
    [
      {
        type   = "metric"
        width  = 24
        height = 6
        properties = {
          title  = "Database exception log lines (read and write failures)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Sum"
          period = var.period_seconds
          metrics = [
            for function in local.database_functions : [var.log_metric_namespace, function.database_failure_metric, { label = function.name }]
          ]
        }
      },
    ],
  )

  ses_widgets = [for widget in [
    {
      type       = "text"
      width      = 24
      height     = 1
      properties = { markdown = "## Email (SES)" }
    },
    {
      type   = "metric"
      width  = 8
      height = 6
      properties = {
        title  = "Sending"
        region = var.aws_region
        view   = "timeSeries"
        stat   = "Sum"
        period = var.period_seconds
        metrics = [
          ["AWS/SES", "Send", { label = "Sent" }],
          ["AWS/SES", "Delivery", { label = "Delivered" }],
          ["AWS/SES", "Bounce", { label = "Bounced" }],
          ["AWS/SES", "Complaint", { label = "Complaints" }],
        ]
      }
    },
    {
      type   = "metric"
      width  = 8
      height = 6
      properties = {
        title   = "Bounce rate"
        region  = var.aws_region
        view    = "timeSeries"
        stat    = "Maximum"
        period  = var.period_seconds
        metrics = [["AWS/SES", "Reputation.BounceRate", { label = "Bounce rate" }]]
        annotations = {
          horizontal = [{ label = "AWS review (5%)", value = 0.05 }]
        }
      }
    },
    {
      type   = "metric"
      width  = 8
      height = 6
      properties = {
        title   = "Complaint rate"
        region  = var.aws_region
        view    = "timeSeries"
        stat    = "Maximum"
        period  = var.period_seconds
        metrics = [["AWS/SES", "Reputation.ComplaintRate", { label = "Complaint rate" }]]
        annotations = {
          horizontal = [{ label = "AWS review (0.1%)", value = 0.001 }]
        }
      }
    },
  ] : widget if var.include_ses]
}

module "dashboard" {
  source = "../../modules/cloudwatch-dashboard"

  dashboard_name = var.dashboard_name
  widgets = concat(
    local.api_widgets,
    local.cloudfront_widgets,
    local.lambda_widgets,
    local.log_widgets,
    local.queue_widgets,
    local.database_widgets,
    local.ses_widgets,
  )
}
