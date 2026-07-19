output "domain_name" {
  value       = aws_cloudfront_distribution.this.domain_name
  description = "CloudFront distribution domain name (e.g. d1234.cloudfront.net)"
}

output "hosted_zone_id" {
  value       = aws_cloudfront_distribution.this.hosted_zone_id
  description = "CloudFront hosted zone ID (always Z2FDTNDATAQYW2)"
}

output "distribution_arn" {
  value       = aws_cloudfront_distribution.this.arn
  description = "ARN of the distribution - used to scope an origin bucket's policy to just this distribution"
}

