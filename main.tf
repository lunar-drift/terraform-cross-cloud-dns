# --- terraform-cross-cloud-dns.main ---

# ===============================================================
#                          ZONES
# ===============================================================
resource "aws_route53_zone" "main" {
  count = local.deploy_aws && var.create_aws_route53_zone ? 1 : 0
  name  = var.domain_name
}

data "aws_route53_zone" "existing" {
  count = local.deploy_aws && !var.create_aws_route53_zone ? 1 : 0
  name  = var.domain_name
  lifecycle {
    # There has been some documented inconsistencies in finding matches with hosted zones
    postcondition {
      condition     = self.name == "${var.domain_name}."
      error_message = "Route53 zone '${var.domain_name}' was not found exactly. Set create_aws_route53_zone = true if the zone should be created, or verify the domain_name value."
    }
  }
}

resource "digitalocean_domain" "main" {
  count = local.deploy_digitalocean && var.create_digitalocean_domain ? 1 : 0
  name  = var.domain_name
}

data "digitalocean_domain" "existing" {
  count = local.deploy_digitalocean && !var.create_digitalocean_domain ? 1 : 0
  name  = var.domain_name
}

data "dnsimple_zone" "existing" {
  count = local.deploy_dnsimple ? 1 : 0
  name  = var.domain_name
}

locals {
  # Ensure zones/domains are in place before attempting to create records
  # one() over splat avoids [0]-index error when the other branch's count = 0
  aws_zone_id         = var.create_aws_route53_zone ? one(aws_route53_zone.main[*].zone_id) : one(data.aws_route53_zone.existing[*].zone_id)
  digitalocean_domain = var.create_digitalocean_domain ? one(digitalocean_domain.main[*].name) : one(data.digitalocean_domain.existing[*].name)
  dnsimple_zone_name  = one(data.dnsimple_zone.existing[*].name)
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
  value    = "${each.value.target}." # FQDN with trailing dot
  ttl      = each.value.ttl
}

resource "dnsimple_zone_record" "mx" {
  for_each = local.deploy_dnsimple ? local.mx_map : {}

  zone_name = local.dnsimple_zone_name
  type      = "MX"
  name      = each.value.name == "@" ? "" : each.value.name
  value     = each.value.target # FQDN required here, even though DNSimple API is lenient with local domain shorthand.
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
