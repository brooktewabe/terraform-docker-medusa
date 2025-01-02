provider "aws" {
  region = var.aws_region
}
locals {
  full_domain = "${var.subdomain}.${var.domain_name}"
}
