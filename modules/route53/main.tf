# Route53 Domains is a global service that only exists in us-east-1,
# regardless of which region the rest of the account's infra runs in.
resource "aws_route53domains_registered_domain" "this" {
  provider = aws.us_east_1

  domain_name = var.domain_name
  auto_renew  = var.auto_renew
  tags        = var.tags
}

# Registering a domain through Route53 Domains auto-creates its public
# hosted zone - looked up here (rather than created) so other modules
# (e.g. ses) can be pointed at its zone_id.
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false

  depends_on = [aws_route53domains_registered_domain.this]
}
