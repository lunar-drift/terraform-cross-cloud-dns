# ==============================================================================
# LOCAL LOGIC & FLATTENING (Provider Toggles & Safe Loop Handling)
# ==============================================================================

locals {
  # Conditional checks to determine which providers are enabled
  deploy_aws          = contains(var.dns_providers, "aws")
  deploy_digitalocean = contains(var.dns_providers, "digitalocean")
  deploy_dnsimple     = contains(var.dns_providers, "dnsimple")

  # Flatten the nested MX records structure cleanly so it never errors out if empty
  # mx_flattened = flatten([
  #   for record_key, mx_list in var.mx_records : [
  #     for item in mx_list : {
  #       key      = record_key
  #       priority = item.priority
  #       value    = item.value
  #     }
  #   ]
  # ])
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
    for name, recs in { for r in local.txt_logical : r.name => r... } :
    name => {
      name   = name
      values = [for rec in recs : rec.value]
      ttl    = recs[0].ttl # same name => same TTL by construction
    }
  }
}
