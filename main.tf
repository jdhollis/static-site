provider "aws" {
  region  = var.region
  profile = var.profile
}

data "aws_route53_zone" "site" {
  name = "${var.domain_name}."
}
