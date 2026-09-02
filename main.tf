# --- terraform-cross-cloud-dns.main ---

# ===============================================================
#                         0. ZONES
# ===============================================================
resource "aws_route53_zone" "main" {
  count = local.deploy_aws ? 1 : 0
  name  = var.domain_name
}

resource "dnsimple_domain" "zone" {
  count          = local.deploy_dnsimple ? 1 : 0
  name           = var.domain_name
  prevent_delete = true
}

# ===============================================================
#                         A RECORDS
# ===============================================================

resource "aws_route53_record" "a" {
  for_each = local.deploy_aws ? local.a_map_aws : {}

  zone_id = aws_route53_zone.main[0].zone_id
  name    = each.value.name == "@" ? var.domain_name : "${each.value.name}.${var.domain_name}"
  type    = "A"
  ttl     = each.value.ttl
  records = each.value.values # round-robin: one record set, N IPs
}

resource "dnsimple_zone_record" "a" {
  for_each = local.deploy_dnsimple ? local.a_map : {}

  zone_name = var.domain_name
  type      = "A"
  name      = each.value.name == "@" ? "" : each.value.name
  value     = each.value.value
  ttl       = each.value.ttl
}

# ===============================================================
#                          CNAME RECORDS
# ===============================================================

resource "aws_route53_record" "cname" {
  for_each = local.deploy_aws ? local.cname_map : {}

  zone_id = aws_route53_zone.main[0].zone_id
  name    = "${each.value.name}.${var.domain_name}" # CNAME records not allowed at `@`
  type    = "CNAME"
  ttl     = each.value.ttl
  records = [each.value.target]
}

resource "dnsimple_zone_record" "cname" {
  for_each = local.deploy_dnsimple ? local.cname_map : {}

  zone_name = var.domain_name
  type      = "CNAME"
  name      = each.value.name   # CNAME records not allowed at `@`
  value     = each.value.target # FQDN required here, even though DNSimple API is lenient.
  ttl       = each.value.ttl
}

# ===============================================================
#                          MX RECORDS
# ===============================================================

resource "aws_route53_record" "mx" {
  for_each = local.deploy_aws ? local.mx_map_aws : {}

  zone_id = aws_route53_zone.main[0].zone_id
  name    = each.value.name == "@" ? var.domain_name : "${each.value.name}.${var.domain_name}"
  type    = "MX"
  ttl     = each.value.ttl
  records = each.value.values
}

# resource "digitalocean_record" "mx" {
#   for_each = local.deploy_digitalocean ? local.mx_map : {}
#
#   domain = var.domain_name
#   type   = "MX"
#   name   = each.value.name
#   priority = each.value.priority
#   value  = each.value.target      # FQDN required here, even though DNSimple API is lenient.
#   ttl    = each.value.ttl
# }

resource "dnsimple_zone_record" "mx" {
  for_each = local.deploy_dnsimple ? local.mx_map : {}

  zone_name = var.domain_name
  type      = "MX"
  name      = each.value.name == "@" ? "" : each.value.name
  value     = each.value.target # FQDN required here, even though DNSimple API is lenient.
  priority  = each.value.priority
  ttl       = each.value.ttl
}

# ===============================================================
#                         TXT RECORDS
# ===============================================================

resource "aws_route53_record" "txt" {
  for_each = local.deploy_aws ? local.txt_map_aws : {}

  zone_id = aws_route53_zone.main[0].zone_id
  name    = each.value.name == "@" ? var.domain_name : "${each.value.name}.${var.domain_name}"
  type    = "TXT"
  ttl     = each.value.ttl
  records = each.value.values
}

resource "dnsimple_zone_record" "txt" {
  for_each = local.deploy_dnsimple ? local.txt_map : {}

  zone_name = var.domain_name
  type      = "TXT"
  name      = each.value.name == "@" ? "" : each.value.name
  value     = each.value.value
  ttl       = each.value.ttl
}
