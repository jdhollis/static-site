resource "aws_s3_bucket" "site" {
  bucket = var.domain_name
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

data "aws_iam_policy_document" "public_read" {
  statement {
    principals {
      identifiers = ["*"]
      type        = "AWS"
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
}

resource "aws_s3_bucket_website_configuration" "www" {
  bucket = aws_s3_bucket.www.bucket

  redirect_all_requests_to {
    host_name = var.domain_name
    protocol  = "https"
  }
}

resource "aws_s3_bucket_public_access_block" "www" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.www.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}
