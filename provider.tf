terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Route53 Domains only exists in us-east-1 - required by modules (e.g.
# route53) that manage domain registrations regardless of var.aws_region.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}


