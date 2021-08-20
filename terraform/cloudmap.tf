##
# This Terraform file creates the Cloud Map namespace, where the preview build hostnames will be registered. 
# AWS Cloud Map is [practically required when using App Mesh](https://docs.aws.amazon.com/app-mesh/latest/userguide/virtual_nodes.html),
# though technically you independently manage DNS records. 

# Create the private hosted zone where Cloud Map will create resource records.
# Use the aws_service_discovery_public_dns_namespace resource for a public hosted zone.
resource "aws_service_discovery_private_dns_namespace" "pr-preview" {
  name        = "pr-preview.example.com"
  description = "A Cloud Map for the staging App Mesh"
  vpc         = data.aws_vpc.staging.id
}

# Fetch the created Route 53 zone from the earlier step.
data "aws_route53_zone" "pr-preview" {
  zone_id = aws_service_discovery_private_dns_namespace.pr-preview.hosted_zone
}

# I'm presuming example.com already exists in Route 53.
data "aws_route53_zone" "example-com" {
  name = "example.com"
}

# Point pr-preview.example.com to the Cloud Map created hosted zone.
resource "aws_route53_record" "pr-preview" {
  zone_id = data.aws_route53_zone.example-com.zone_id
  name    = "pr-preview"
  type    = "NS"
  ttl     = 43200
  records = data.aws_route53_zone.pr-preview.name_servers
}

# Point *.pr-preview.example.com to the AWS LB that fronts the App Mesh Virtual Gateway.
resource "aws_route53_record" "wildcard-pr-preview-example-com" {
  zone_id = aws_service_discovery_private_dns_namespace.pr-preview.hosted_zone
  name    = "*"
  type    = "A"

  alias {
    name                   = aws_lb.pr-preview-example-com.dns_name
    zone_id                = aws_lb.pr-preview-example-com.zone_id
    evaluate_target_health = false
  }
}


# Either create your certificate using ACM,
resource "aws_acm_certificate" "pr-preview-example-com-wildcard-tls" {
  domain_name = "*.pr-preview.example.com"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "pr-preview-example-com-wildcard-tls" {
  for_each = {
    for dvo in aws_acm_certificate.pr-preview-example-com-wildcard-tls.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.pr-preview.zone_id
}

resource "aws_acm_certificate_validation" "pr-preview-example-com-wildcard-tls" {
  certificate_arn         = aws_acm_certificate.pr-preview-example-com-wildcard-tls.arn
  validation_record_fqdns = [for record in aws_route53_record.pr-preview-example-com-wildcard-tls : record.fqdn]
}


## Or import an existing one from ACM. 
# data "aws_acm_certificate" "pr-preview-example-com-wildcard-tls" {
#  domain      = "*.pr-preview.example.com"
#  types       = ["AMAZON_ISSUED"]
#  most_recent = true
# }
