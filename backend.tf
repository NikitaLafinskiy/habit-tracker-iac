terraform {
  # Points at the bucket/table provisioned by bootstrap/ (see
  # bootstrap/terraform.tfvars for the actual names used). Hardcoded here
  # so `terraform init` needs no -backend-config flags.
  backend "s3" {
    bucket         = "habit-tracker-statetf"
    key            = "iac/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "habit-tracker-locktf"
  }
}

