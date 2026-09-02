# --- terraform-cross-cloud-dns.outputs ---

locals {
  # Provider-neutral grouped record inventory, keyed type -> name.
  # Values are raw strings exactly as the user supplied them; "@" denotes apex.
  records_by_type = {
    TXT = {
      for name, recs in { for r in local.txt_logical : r.name => r... } :
      name => {
        values = [for rec in recs : rec.value]
        ttl    = recs[0].ttl
      }
    }
    A = {
      for name, recs in { for r in local.a_logical : r.name => r... } :
      name => {
        values = [for rec in recs : rec.value]
        ttl    = recs[0].ttl
      }
    }
    CNAME = {
      for name, r in local.cname_map :
      name => {
        values = [r.target]
        ttl    = r.ttl
      }
    }
    MX = {
      for name, recs in { for r in local.mx_logical : r.name => r... } :
      name => {
        values = [for rec in recs : "${rec.priority} ${rec.target}"]
        ttl    = recs[0].ttl
      }
    }
  }

  # Which providers these records are (or were intended to be) deployed to
  providers_in_use = [
    for p, enabled in {
      aws          = local.deploy_aws
      dnsimple     = local.deploy_dnsimple
      digitalocean = local.deploy_digitalocean
    } : p if enabled
  ]
}

output "dns_records" {
  description = "Complete DNS inventory: record type -> record name -> {values, ttl}. '@' = zone apex."
  value = {
    domain    = var.domain_name
    providers = local.providers_in_use
    records   = local.records_by_type
  }
}