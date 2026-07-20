resource "aws_dynamodb_table" "this" {
  name           = var.name
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  hash_key       = var.hash_key
  range_key      = var.range_key

  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  tags = var.tags
}

# For small, static reference data (lookup/enum-backed tables) known at plan
# time - not a fit for larger or dynamic seed data, which belongs in an
# app-level seeder or a one-off script instead.
resource "aws_dynamodb_table_item" "seed" {
  for_each = var.items

  table_name = aws_dynamodb_table.this.name
  hash_key   = var.hash_key
  item       = each.value
}
