variable "domain_name" {}

variable "profile" {
  default = "default"
}

variable "region" {
  default = "us-east-1"
}

variable "routing_rules" {
  default = ""
}

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}
