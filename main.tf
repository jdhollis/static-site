provider "aws" {
  version = "~> 3.18"
  region  = var.region
  profile = var.profile
}

data "aws_route53_zone" "site" {
  name = "${var.domain_name}."
}

resource "aws_acm_certificate" "site" {
  domain_name       = var.domain_name
  validation_method = "DNS"
}

resource "aws_route53_record" "site_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type
  zone_id = data.aws_route53_zone.site.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for record in aws_route53_record.site_cert_validation : record.fqdn]
}

resource "aws_s3_bucket" "site" {
  bucket = var.domain_name

  website {
    index_document = "index.html"
    error_document = "404.html"
    routing_rules  = var.routing_rules
  }
}

data "aws_iam_policy_document" "public_read" {
  statement {
    principals {
      identifiers = ["*"]
      type = "AWS"
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.public_read.json
}

resource "aws_s3_bucket" "www" {
  bucket = "www.${var.domain_name}"

  website {
    redirect_all_requests_to = "https://${var.domain_name}"
  }
}

resource "aws_s3_bucket_public_access_block" "www" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.www.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

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
