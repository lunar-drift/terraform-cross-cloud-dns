# --- terraform-cross-cloud-dns.outputs ---

output "dns_records" {
  description = "Complete DNS inventory: record type -> record name -> {values, ttl}. '@' = zone apex."
  value = {
    domain    = var.domain_name
    providers = local.providers_in_use
    records   = local.records_by_type
  }
}