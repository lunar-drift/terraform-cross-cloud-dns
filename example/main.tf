module "x_dns" {
  source = "../"
  domain_name = "webdatabasesolutions.com"
  dns_providers = ["aws", "dnsimple"]
  default_ttl = 60

  txt_records = {
    "@" = [
      "v=spf1 include:_spf.google.com ~all",
      "google-site-verification=abc123",
    ]
    "_dmarc" = ["v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s"]
  }
  cname_records = {
    "dkim._domainkey" = ["dkim._domainkey.alias.proton.me"]
    "dkim02._domainkey" = ["dkim02._domainkey.alias.proton.me"]
    "dkim03._domainkey" = ["dkim03._domainkey.alias.proton.me"]
  }
}

locals {
  proton_pass_mx_records = {
    type    = "MX"
    name    = "webdatabasesolutions.com"
    records = [
      "10 mx1.alias.proton.me",
      "20 mx2.alias.proton.me"
    ]
    ttl = 86400
  }
}
