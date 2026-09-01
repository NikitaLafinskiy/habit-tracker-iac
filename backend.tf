terraform {
  # Bucket/table are provisioned by bootstrap/ (see bootstrap/terraform.tfvars
  # for the actual names). The state key is the only per-environment part, so
  # it is supplied at init instead of being hardcoded here - see
  # doc/CLAUDE.md "Environments".
  backend "s3" {
    bucket         = "habit-tracker-statetf"
    region         = "eu-central-1"
    dynamodb_table = "habit-tracker-locktf"
  }
}
