# --- terraform-cross-cloud-dns.main ---

# ===============================================================
#                          ZONES
# ===============================================================
resource "aws_route53_zone" "main" {
  count = local.deploy_aws && var.create_aws_route53_zone ? 1 : 0
  name  = var.domain_name
}

resource "dnsimple_domain" "main" {
  count          = local.deploy_dnsimple && var.create_dnsimple_domain ? 1 : 0
  name           = var.domain_name
  prevent_delete = true
}

resource "digitalocean_domain" "main" {
  count = local.deploy_digitalocean && var.create_digitalocean_domain ? 1 : 0
  name  = var.domain_name
}

# ===============================================================
#                         A RECORDS
# ===============================================================

resource "aws_route53_record" "a" {
  for_each = local.deploy_aws ? local.a_map_aws : {}

  zone_id = local.aws_zone_id
  name    = each.value.name == "@" ? var.domain_name : "${each.value.name}.${var.domain_name}"
  type    = "A"
  ttl     = each.value.ttl
  records = each.value.values # round-robin: one record set, N IPs
}

resource "digitalocean_record" "a" {
  for_each = local.deploy_digitalocean ? local.a_map : {}

  domain = local.digitalocean_domain
  type   = "A"
  name   = each.value.name
  value  = each.value.value
  ttl    = each.value.ttl
}

resource "dnsimple_zone_record" "a" {
  for_each = local.deploy_dnsimple ? local.a_map : {}

  zone_name = local.dnsimple_zone_name
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

  zone_id = local.aws_zone_id
  name    = "${each.value.name}.${var.domain_name}" # FQDN required for name in AWS API
  type    = "CNAME"
  ttl     = each.value.ttl
  records = [each.value.target]
}

resource "digitalocean_record" "cname" {
  for_each = local.deploy_digitalocean ? local.cname_map : {}

  domain = local.digitalocean_domain
  type   = "CNAME"
  name   = each.value.name
  value  = "${each.value.target}." # FQDN with trailing dot
  ttl    = each.value.ttl
}

resource "dnsimple_zone_record" "cname" {
  for_each = local.deploy_dnsimple ? local.cname_map : {}

  zone_name = local.dnsimple_zone_name
  type      = "CNAME"
  name      = each.value.name
  value     = each.value.target # FQDN required here, even though DNSimple API is lenient.
  ttl       = each.value.ttl
}

# ===============================================================
#                          MX RECORDS
# ===============================================================

resource "aws_route53_record" "mx" {
  for_each = local.deploy_aws ? local.mx_map_aws : {}

  zone_id = local.aws_zone_id
  name    = each.value.name == "@" ? var.domain_name : "${each.value.name}.${var.domain_name}"
  type    = "MX"
  ttl     = each.value.ttl
  records = each.value.values
}

resource "digitalocean_record" "mx" {
  for_each = local.deploy_digitalocean ? local.mx_map : {}

  domain   = local.digitalocean_domain
  type     = "MX"
  name     = each.value.name
  priority = each.value.priority
  value    = each.value.target # FQDN required here, even though this API is lenient.
  ttl      = each.value.ttl
}

resource "dnsimple_zone_record" "mx" {
  for_each = local.deploy_dnsimple ? local.mx_map : {}

  zone_name = local.dnsimple_zone_name
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

  zone_id = local.aws_zone_id
  name    = each.value.name == "@" ? var.domain_name : "${each.value.name}.${var.domain_name}"
  type    = "TXT"
  ttl     = each.value.ttl
  records = each.value.values
}

resource "digitalocean_record" "txt" {
  for_each = local.deploy_digitalocean ? local.txt_map : {}

  domain = local.digitalocean_domain
  type   = "TXT"
  name   = each.value.name # "@" passes through natively
  value  = each.value.value
  ttl    = each.value.ttl
}

resource "dnsimple_zone_record" "txt" {
  for_each = local.deploy_dnsimple ? local.txt_map : {}

  zone_name = local.dnsimple_zone_name
  type      = "TXT"
  name      = each.value.name == "@" ? "" : each.value.name
  value     = each.value.value
  ttl       = each.value.ttl
}
