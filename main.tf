# --- terraform-cross-cloud-dns.main ---
# ==============================================================================
# 1. AWS ROUTE 53 RESOURCES
# ==============================================================================
resource "aws_route53_zone" "main" {
  count = local.deploy_aws ? 1 : 0
  name  = var.domain_name
}


resource "aws_route53_record" "txt" {
  for_each = local.deploy_aws ? local.txt_map_aws : {}

  zone_id = aws_route53_zone.main[0].zone_id
  name    = each.value.name == "@" ? var.domain_name : "${each.value.name}.${var.domain_name}"
  type    = "TXT"
  ttl     = each.value.ttl
  records = each.value.values
}

resource "aws_route53_record" "a" {
  for_each = local.deploy_aws ? local.a_map_aws : {}

  zone_id = aws_route53_zone.main[0].zone_id
  name    = each.value.name == "@" ? var.domain_name : "${each.value.name}.${var.domain_name}"
  type    = "A"
  ttl     = each.value.ttl
  records = each.value.values # round-robin: one record set, N IPs
}

resource "aws_route53_record" "cname" {
  for_each = local.deploy_aws ? local.cname_map : {}

  zone_id = aws_route53_zone.main[0].zone_id
  name    = "${each.value.name}.${var.domain_name}" # CNAME records not allowed at `@`
  type    = "CNAME"
  ttl     = each.value.ttl
  records = [each.value.target]
}

# ==============================================================================
# 2. DNSIMPLE RESOURCES
# ==============================================================================
resource "dnsimple_domain" "zone" {
  count          = local.deploy_dnsimple ? 1 : 0
  name           = var.domain_name
  prevent_delete = true
}

# DNSimple: one dnsimple_zone_record per logical value (same as AWS mapping,
# just rendered as separate API objects)
resource "dnsimple_zone_record" "txt" {
  for_each = local.deploy_dnsimple ? local.txt_map : {}

  zone_name = var.domain_name
  type      = "TXT"
  name      = each.value.name == "@" ? "" : each.value.name
  value     = each.value.value
  ttl       = each.value.ttl
}

resource "dnsimple_zone_record" "a" {
  for_each = local.deploy_dnsimple ? local.a_map : {}

  zone_name = var.domain_name
  type      = "A"
  name      = each.value.name == "@" ? "" : each.value.name
  value     = each.value.value
  ttl       = each.value.ttl
}

resource "dnsimple_zone_record" "cname" {
  for_each = local.deploy_dnsimple ? local.cname_map : {}

  zone_name = var.domain_name
  type      = "CNAME"
  name      = each.value.name   # apex forbidden by validation upstream
  value     = each.value.target # FQDN required here, normalized in cname_map
  ttl       = each.value.ttl
}
