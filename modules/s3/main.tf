resource "aws_s3_bucket" "this" {
  bucket = var.name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Opt-in: only created when expiration_days is set, so the build-artifact
# buckets keep no lifecycle configuration at all. See doc/CLAUDE.md for why a
# versioned bucket needs all three rules rather than just an expiration.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.expiration_days == null ? 0 : 1
  bucket = aws_s3_bucket.this.id

  # Noncurrent-version rules only mean anything once versioning exists, and
  # nothing else orders the two resources.
  depends_on = [aws_s3_bucket_versioning.this]

  rule {
    id     = "expire-objects"
    status = "Enabled"

    # An empty prefix means the whole bucket. The filter block itself is
    # required by the provider; omitting it is a deprecation warning.
    filter {
      prefix = var.expiration_prefix
    }

    expiration {
      days = var.expiration_days
    }

    # Load-bearing on a versioned bucket. `expiration` above only writes a
    # delete marker there - the object's bytes survive as a noncurrent version
    # indefinitely, so without this the rule hides data instead of deleting it
    # and keeps billing for it.
    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    # A failed multipart upload otherwise leaves parts that never show up in
    # the console and never expire on their own.
    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }

  # A separate rule because S3 rejects `days` and `expired_object_delete_marker`
  # in the same expiration block. Sweeps up the markers the rule above leaves
  # behind once every version beneath them is gone.
  rule {
    id     = "expire-delete-markers"
    status = "Enabled"

    filter {
      prefix = var.expiration_prefix
    }

    expiration {
      expired_object_delete_marker = true
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_policy" "this" {
  count  = var.is_public ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.allow_public_read.json

  # Explicit dependency: AWS rejects a public policy while the access
  # block is still restrictive, and nothing else orders them (see doc/CLAUDE.md).
  depends_on = [aws_s3_bucket_public_access_block.this]
}

data "aws_iam_policy_document" "allow_public_read" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}

# Add static website config (SPAs need the error document)
resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.is_public ? 1 : 0
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # so client‑side routing works
  }
}
