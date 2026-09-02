# --- terraform-cross-cloud-dns/example/main.tf ---

module "ld_dns" {
  source        = "../"
  domain_name   = var.domain_name
  dns_providers = ["aws", "dnsimple", "digitalocean"]

  create_aws_route53_zone = true
  create_digitalocean_domain = true

  default_ttl   = 60

  txt_records = {
    "@" = [
      "v=spf1 include:spf.example.net ~all",
      "site-verification=elvispresleyfan",
    ]
    "_dmarc" = ["v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s"]
  }
  cname_records = {
    "docs"    = "docs.external-provider.com"
    "status"  = "status-page.example-hosted.io"
  }

  mx_records = {
    "@" = [
      { priority = 10, value = "mx1.mail-provider.net" },
      { priority = 20, value = "mx2.mail-provider.net" },
    ]
  }
  a_records = {
    "@" = ["203.0.113.10"]
    "www" = ["203.0.113.20", "203.0.113.21"]
  }
}

output "all_records" {
  value = module.ld_dns.dns_records
}
