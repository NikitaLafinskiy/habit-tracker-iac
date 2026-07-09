terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Deliberately no `backend` block: this config provisions the remote
  # state bucket and lock table themselves, so it has to run on local
  # state until they exist. Once applied, every other Terraform root
  # (auth/.infra, iac's own root config, ...) points its S3 backend at
  # the bucket/table created here.
}

provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}
