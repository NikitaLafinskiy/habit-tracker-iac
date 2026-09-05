resource "aws_dsql_cluster" "this" {
  deletion_protection_enabled = var.deletion_protection_enabled

  tags = var.tags
}
