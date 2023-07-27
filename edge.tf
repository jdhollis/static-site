resource "aws_cloudfront_distribution" "site" {
  depends_on = [aws_acm_certificate_validation.cert]

  origin {
    domain_name = aws_s3_bucket.site.website_endpoint
    origin_id   = "S3-Website-${aws_s3_bucket.site.website_endpoint}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"

      origin_ssl_protocols = [
        "TLSv1",
        "TLSv1.1",
        "TLSv1.2",
      ]
    }
  }

  aliases         = [var.domain_name]
  is_ipv6_enabled = true
  enabled         = true

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.site.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  default_cache_behavior {
    target_origin_id       = "S3-Website-${aws_s3_bucket.site.website_endpoint}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      cookies {
        forward = "none"
      }

      query_string = false
    }

    min_ttl     = 0
    max_ttl     = 31536000
    default_ttl = 86400
    compress    = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_route53_record" "site" {
  name    = var.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.site.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
  }
}

resource "aws_route53_record" "www" {
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  zone_id = data.aws_route53_zone.site.zone_id
  records = [aws_s3_bucket.www.website_endpoint]
  ttl     = 172800
}
