data "aws_lambda_function" "this" {
  for_each = local.functions

  function_name = each.value.name
}

data "aws_resourcegroupstaggingapi_resources" "dsql" {
  for_each = local.databases

  resource_type_filters = ["dsql:cluster"]

  tag_filter {
    key    = "Name"
    values = [each.value]
  }
}
