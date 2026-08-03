resource "aws_cloudfront_origin_access_control" "this" {
  count = var.enable_origin_access_control ? 1 : 0

  name                              = "${var.origin_id}-oac"
  origin_access_control_origin_type = var.origin_access_control_type
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = var.origin_domain_name
    origin_id   = var.origin_id

    # origin_access_control_id is a plain optional attribute on this block,
    # not a nested block itself - `null` when OAC is disabled.
    origin_access_control_id = var.enable_origin_access_control ? aws_cloudfront_origin_access_control.this[0].id : null
  }

  enabled             = true
  is_ipv6_enabled     = var.is_ipv6_enabled
  comment             = var.comment
  default_root_object = var.default_root_object
  aliases             = var.aliases

  default_cache_behavior {
    target_origin_id = var.origin_id

    allowed_methods = var.cache_allowed_methods
    cached_methods  = var.cache_cached_methods

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = var.viewer_protocol_policy
    min_ttl                = var.cache_min_ttl
    default_ttl            = var.cache_default_ttl
    max_ttl                = var.cache_max_ttl
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = var.tags

  # Falls back to the CloudFront default cert when acm_certificate_arn is
  # unset - only pass it once var.aliases is also set (see doc/CLAUDE.md).
  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == null
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = var.acm_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != null ? "TLSv1.2_2021" : null
  }
}
