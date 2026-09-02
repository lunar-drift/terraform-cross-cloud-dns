# --- terraform-cross-cloud-dns.locals ---

locals {
  # Conditional checks to determine which providers are enabled
  deploy_aws          = contains(var.dns_providers, "aws")
  deploy_digitalocean = contains(var.dns_providers, "digitalocean")
  deploy_dnsimple     = contains(var.dns_providers, "dnsimple")

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
      target = strcontains(target, ".") ? target : "${target}.${var.domain_name}" # allows for shorthand for referencing local domain name.
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
        target   = strcontains(mx.value, ".") ? mx.value : "${mx.value}.${var.domain_name}"
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
