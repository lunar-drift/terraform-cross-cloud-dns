# --- terraform-cross-cloud-dns.locals ---

locals {
  # Conditional checks to determine which providers are enabled
  deploy_aws          = contains(var.dns_providers, "aws")
  deploy_digitalocean = contains(var.dns_providers, "digitalocean")
  deploy_dnsimple     = contains(var.dns_providers, "dnsimple")

  aws_zone_id         = var.create_aws_route53_zone ? one(aws_route53_zone.main[*].zone_id) : var.aws_route53_zone_id
  dnsimple_zone_name  = var.create_dnsimple_domain ? one(dnsimple_domain.main[*].name) : var.domain_name
  digitalocean_domain = var.create_digitalocean_domain ? one(digitalocean_domain.main[*].name) : var.domain_name

  # -- A records --
  a_logical = flatten([
    for name, ips in var.a_records : [
      for ip in ips : {
        key   = "${name}_${md5(ip)}"
        name  = name
        value = ip
        ttl   = lookup(var.per_subdomain_ttl, name, var.default_ttl)
      }
    ]
  ])
  a_map = { for r in local.a_logical : r.key => r }
  a_map_aws = {
    # AWS Route 53 accepts multiple values per subdomain within one record resource.
    for name, recs in { for r in local.a_logical : r.name => r... } :
    name => {
      name   = name
      values = [for rec in recs : rec.value]
      ttl    = recs[0].ttl
    }
  }
  # -- CNAME: single-valued, so no logical intermediary for RR set model/RR model distinction --
  cname_map = {
    for name, target in var.cname_records :
    name => {
      name   = name
      target = target
      ttl    = lookup(var.per_subdomain_ttl, name, var.default_ttl)
    }
  }

  # -- MX RECORDS: ---
  mx_logical = flatten([
    for name, entries in var.mx_records : [
      for mx in entries : {
        key      = "${name}_${mx.priority}_${md5(mx.value)}"
        name     = name
        priority = mx.priority
        target   = mx.value
        ttl      = lookup(var.per_subdomain_ttl, name, var.default_ttl)
      }
    ]
  ])
  mx_map = { for r in local.mx_logical : r.key => r }
  mx_map_aws = {
    for name, recs in { for r in local.mx_logical : r.name => r... } :
    name => {
      name   = name
      values = [for rec in recs : "${rec.priority} ${rec.target}"]
      ttl    = recs[0].ttl
    }
  }

  # -- TXT records --
  txt_logical = flatten([
    for name, values in var.txt_records : [
      for value in values : {
        key   = "${name}_${md5(value)}" # stable unique key even for duplicate names
        name  = name
        value = value
        ttl   = lookup(var.per_subdomain_ttl, name, var.default_ttl)
      }
    ]
  ])
  txt_map = { for r in local.txt_logical : r.key => r }
  txt_map_aws = {
    # AWS Route 53 accepts multiple values per subdomain within one record resource.
    for name, recs in { for r in local.txt_logical : r.name => r... } :
    name => {
      name   = name
      values = [for rec in recs : rec.value]
      ttl    = recs[0].ttl
    }
  }
}
