aws_region = "eu-central-1"

environment = "dev"

# No domain_name: dev is backend-only. The domain registration, ACM
# certificate, CloudFront distribution, client-artifacts bucket and apex DNS
# record are all prod-only (see main.tf) - dev is reached at its API Gateway
# invoke URL, and the client runs locally against it.
