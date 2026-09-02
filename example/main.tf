module "ld_dns" {
  source        = "../"
  domain_name   = "webdatabasesolutions.com"
  dns_providers = ["aws", "dnsimple", "digitalocean"]
  create_aws_route53_zone = true
  create_digitalocean_domain = true

  default_ttl   = 60

  txt_records = {
    "@" = [
      "v=spf1 include:_spf.google.com ~all",
      "google-site-verification=abc123",
    ]
    "_dmarc" = ["v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s"]
  }
  cname_records = {
    "dkim._domainkey"   = "dkim._domainkey.google.com"
    "dkim02._domainkey" = "dkim02._domainkey.google.com"
    "dkim03._domainkey" = "dkim03._domainkey.google.com"
  }

  mx_records = {
    "@" = [
      { priority = 10, value = "mx1.forward-email.net" },
      { priority = 20, value = "mx2.forward-email.net" },
    ]
  }
  a_records = {
    "@" = ["150.0.0.1"]
    "www" = ["150.0.0.2", "150.0.0.3"]
  }
}


output "all_records" {
  value = module.ld_dns.dns_records
}
