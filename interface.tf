variable "domain_name" {}

variable "profile" {
  default = "default"
}

variable "region" {
  default = "us-east-1"
}

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}
