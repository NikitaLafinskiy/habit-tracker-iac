terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "habit-tracker-statetf"
    key            = "bootstrap/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "habit-tracker-locktf"
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}
