locals {
  actions = [var.alarm_topic_arn]

  database_functions = {
    for key, function in var.functions : key => function if function.database_failure_metric != null
  }
}
