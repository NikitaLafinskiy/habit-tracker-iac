output "domain_name" {
  value = aws_route53domains_registered_domain.this.domain_name
}

output "zone_id" {
  value = data.aws_route53_zone.this.zone_id
}

output "expiration_date" {
  value = aws_route53domains_registered_domain.this.expiration_date
}
