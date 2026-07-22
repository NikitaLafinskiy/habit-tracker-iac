output "arn" {
  value = aws_ses_domain_identity.this.arn
}

output "domain" {
  value = aws_ses_domain_identity.this.domain
}

output "configuration_set_name" {
  value = try(aws_ses_configuration_set.this[0].name, null)
}
