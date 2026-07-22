output "arn" {
  value = aws_ses_domain_identity.this.arn
}

output "domain" {
  value = aws_ses_domain_identity.this.domain
}

output "configuration_set_name" {
  value = try(aws_ses_configuration_set.this[0].name, null)
}

# Constructed rather than read off the resource - aws_ses_configuration_set
# (the SESv1 resource) doesn't export an arn attribute of its own, unlike
# its SESv2 counterpart, but the format is fixed/documented by AWS so this
# is exact.
output "configuration_set_arn" {
  value = try(
    "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:configuration-set/${aws_ses_configuration_set.this[0].name}",
    null
  )
}
