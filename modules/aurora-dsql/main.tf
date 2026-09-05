data "aws_region" "current" {}

resource "aws_dsql_cluster" "this" {
  deletion_protection_enabled = var.deletion_protection_enabled

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    prevent_destroy = true
  }
}
