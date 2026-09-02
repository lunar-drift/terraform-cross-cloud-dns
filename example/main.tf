module "ld_dns" {
  source = "../"
  domain_name = "webdatabasesolutions.com"
  dns_providers = ["aws", "dnsimple"]
  default_ttl   = 60

  txt_records = {
    "@" = [
      "v=spf1 include:_spf.google.com ~all",
      "google-site-verification=abc123",
    ]
    "_dmarc" = ["v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s"]
  }
  cname_records = {
    "dkim._domainkey"   = "dkim._domainkey.alias.proton.me"
    "dkim02._domainkey" = "dkim02._domainkey.alias.proton.me"
    "dkim03._domainkey" = "dkim03._domainkey.alias.proton.me"
  }

  mx_records = {
    "@" = [
      { priority = 10, value = "mx1.forward-email.net" },
      { priority = 20, value = "mx2.forward-email.net" },
    ]
  }
}


output "all_records" {
  value = module.ld_dns.dns_records
}

output "mx1" {
  value = module.ld_dns._mx_var
}
output "mx2" {
  value = module.ld_dns._mx_logical
}
output "mx3" {
  value = module.ld_dns._mx_map
}
output "mx4" {
  value = module.ld_dns._mx_map_aws
}
