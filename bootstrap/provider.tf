terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # No `backend` block: this config creates the remote state bucket/lock
  # table itself, so it must run on local state first (see doc/CLAUDE.md).
}

provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}
