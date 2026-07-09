resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name

  # Remote state is high-blast-radius if ever deleted; require an explicit
  # `terraform destroy -target` after removing this guard, not a plain apply.
  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Matches the `dynamodb_table = "tflock"` already hard-coded in every
# consumer's backend.tf (auth/.infra/backend.tf, iac/backend.tf).
module "lock_table" {
  source = "../modules/dynamodb"

  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attributes = [
    { name = "LockID", type = "S" }
  ]
  tags = var.tags
}
