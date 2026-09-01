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
}
