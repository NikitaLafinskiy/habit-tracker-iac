data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_ses_domain_identity" "this" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

resource "aws_route53_record" "verification" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.this.verification_token]
}

resource "aws_route53_record" "dkim" {
  count = 3

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# Blocks `apply` until SES actually confirms the domain as verified (polls
# up to the provider's default timeout), so anything depending on this
# module's output only becomes available once sending is actually possible.
resource "aws_ses_domain_identity_verification" "this" {
  domain = aws_ses_domain_identity.this.domain

  depends_on = [aws_route53_record.verification]
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Only created when the caller opts in - callers that leave
# create_notifications false get plain domain/DKIM verification only, same
# as before this was added.
resource "aws_ses_configuration_set" "this" {
  count = var.create_notifications ? 1 : 0

  name = "${replace(var.domain_name, ".", "-")}-events"
}

resource "aws_ses_event_destination" "sns" {
  count = var.create_notifications ? 1 : 0

  name                   = "${replace(var.domain_name, ".", "-")}-sns-events"
  configuration_set_name = aws_ses_configuration_set.this[0].name
  enabled                = true
  matching_types         = ["bounce", "complaint"]

  sns_destination {
    topic_arn = var.notification_topic_arn
  }
}

# Grants SES itself (not the sending Lambda) permission to publish to the
# caller-provided topic - the topic's own module doesn't know it'll be used
# for SES events, so that permission is attached here instead.
data "aws_iam_policy_document" "sns_publish_from_ses" {
  count = var.create_notifications ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    resources = [var.notification_topic_arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "notifications" {
  count = var.create_notifications ? 1 : 0

  arn    = var.notification_topic_arn
  policy = data.aws_iam_policy_document.sns_publish_from_ses[0].json
}
