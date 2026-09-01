# --- terraform-cross-cloud-dns.main ---
# ==============================================================================
# 1. AWS ROUTE 53 RESOURCES
# ==============================================================================
resource "aws_route53_zone" "main" {
  count = local.deploy_aws ? 1 : 0
  name  = var.domain_name
}

resource "aws_route53_record" "txt" {
  for_each = local.deploy_aws ? var.txt_records : {}

  zone_id = aws_route53_zone.main[0].zone_id
  name    = each.key == "@" ? var.domain_name : "${each.key}.${var.domain_name}"
  type    = "TXT"
  ttl     = var.per_subdomain_ttl[each.key]
  records = [each.value]
}

# ==============================================================================
# 2. DNSIMPLE RESOURCES
# ==============================================================================
resource "dnsimple_domain" "zone" {
  name           = var.domain_name
  prevent_delete = true
}

resource "dnsimple_zone_record" "txt" {
  for_each = local.deploy_dnsimple ? var.txt_records : {}

  zone_name  = var.domain_name
  type       = "TXT"
  name       = each.key == "@" ? "" : each.key
  value      = each.value
  ttl        = var.per_subdomain_ttl[each.key]
}
