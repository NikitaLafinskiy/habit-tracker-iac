resource "aws_iam_user" "this" {
  name = var.name
  tags = var.tags
}

data "aws_iam_policy_document" "this" {
  dynamic "statement" {
    for_each = var.policy_statements
    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_user_policy" "this" {
  name   = var.name
  user   = aws_iam_user.this.name
  policy = data.aws_iam_policy_document.this.json
}
