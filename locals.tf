# --- terraform-cross-cloud-dns.locals ---

locals {
  # Conditional checks to determine which providers are enabled
  deploy_aws          = contains(var.dns_providers, "aws")
  deploy_digitalocean = contains(var.dns_providers, "digitalocean")
  deploy_dnsimple     = contains(var.dns_providers, "dnsimple")

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
  # ---- A records: identical machinery to TXT ----
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
  # ---- CNAMEs: single-valued, so no flatten — the input IS the logical map ----
  cname_map = {
    for name, target in var.cname_records :
    name => {
      name   = name
      target = strcontains(target, ".") ? target : "${target}.${var.domain_name}" # allows for shorthand for referencing local domain name.
      ttl    = lookup(var.per_subdomain_ttl, name, var.default_ttl)
    }
  }


}
