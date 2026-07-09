terraform {
  # No remote state bucket exists yet. The bucket (and any key prefix) must
  # be supplied at `terraform init -backend-config=...` time once one is
  # provisioned; until then this partial config lets `init` fall back to
  # asking for it interactively.
  backend "s3" {
    region         = "eu-central-1"
    dynamodb_table = "tflock"
  }
}

