locals {
  suffix  = var.environment == "prod" ? "" : "-${var.environment}"
  is_prod = var.environment == "prod"
  name    = "habit-tracker${local.suffix}"

  log_metric_namespace = "HabitTracker/Logs"
  error_log_pattern    = "\"ERROR [\""
  database_failure_pattern = join(" ", [
    "?PSQLException",
    "?DataAccessException",
    "?TransactionSystemException",
    "?CannotCreateTransactionException",
    "?JDBCConnectionException",
    "?SQLTransientConnectionException",
  ])

  functions = {
    api = {
      name         = "api${local.suffix}"
      has_database = true
    }
    auth = {
      name         = "auth${local.suffix}"
      has_database = true
    }
    ai-insight = {
      name         = "ai-insight${local.suffix}"
      has_database = false
    }
  }

  queues = {
    api = {
      queue = "api${local.suffix}-queue"
      dlq   = "api${local.suffix}-dlq"
    }
    auth-email = {
      queue = "auth${local.suffix}-email-queue"
      dlq   = "auth${local.suffix}-email-dlq"
    }
    ai-insight = {
      queue = "ai-insight${local.suffix}-queue"
      dlq   = "ai-insight${local.suffix}-dlq"
    }
  }

  databases = {
    api  = "api-dsql${local.suffix}"
    auth = "auth-dsql${local.suffix}"
  }

  monitored_functions = {
    for key, function in local.functions : key => {
      name                    = function.name
      log_group_name          = "/aws/lambda/${function.name}"
      timeout_seconds         = data.aws_lambda_function.this[key].timeout
      error_log_metric        = "${function.name}-error-log-lines"
      database_failure_metric = function.has_database ? "${function.name}-database-failure-lines" : null
    }
  }

  database_clusters = {
    for key, lookup in data.aws_resourcegroupstaggingapi_resources.dsql :
    key => element(split("/", one(lookup.resource_tag_mapping_list).resource_arn), 1)
  }
}
