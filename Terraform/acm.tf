data "aws_route53_zone" "medusa_zone" {
  name         = var.domain_name
  private_zone = false
}

# Fetch the existing ACM certificate
data "aws_acm_certificate" "existing_cert" {
  domain      = var.certificate_domain
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_route53_record" "medusa_domain" {
  zone_id = data.aws_route53_zone.medusa_zone.zone_id
  name    = local.full_domain
  type    = "A"

  alias {
    name                   = aws_lb.medusa_alb.dns_name
    zone_id                = aws_lb.medusa_alb.zone_id
    evaluate_target_health = true
  }
}