output "arn" {
  value = aws_ses_domain_identity.this.arn
}

output "domain" {
  value = aws_ses_domain_identity.this.domain
}

output "configuration_set_name" {
  value = try(aws_ses_configuration_set.this[0].name, null)
}

# Constructed - the SESv1 aws_ses_configuration_set has no arn attribute
# of its own, but AWS's ARN format is fixed/documented.
output "configuration_set_arn" {
  value = try(
    "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:configuration-set/${aws_ses_configuration_set.this[0].name}",
    null
  )
}
