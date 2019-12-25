# static-site

A Terraform module for setting up a static site with SSL using CloudFront and S3.

The site is served from the apex domain (e.g., https://theconsultingcto.com) with a redirect from www to the apex domain (e.g., https://www.theconsultingcto.com redirects to https://theconsultingcto.com). The CloudFront distribution also automatically redirects from http to https.

This module assumes you've already set up a Route 53 zone for the desired domain name.

## Usage

```hcl
module "site" {
  source      = "github.com/jdhollis/static-site"
  domain_name = "" # Insert your domain name here
}
``` 
