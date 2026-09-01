module "zone_records" {
  source = "../"
  txt_records = {
    "@" = "v=spf1 include:alias.proton.me ~all"
  }

  dns_providers = ["aws"]
  per_subdomain_ttl = {
    "www"               = 86400
    "@"                 = 86400
    "dkim._domainkey"   = 86400
    "dkim02._domainkey" = 86400
  }
}

locals {
  zone_id = ""
  dns_records = {
    text_records = {
      zone_id = local.zone_id
      type    = "TXT"
      name    = "webdatabasesolutions.com"
      records = [
        "v=spf1 include:alias.proton.me ~all"
      ]
      ttl = 86400
    }
    proton_pass_mx_records = {
      zone_id = local.zone_id
      type    = "MX"
      name    = "webdatabasesolutions.com"
      records = [
        "10 mx1.alias.proton.me",
        "20 mx2.alias.proton.me"
      ]
      ttl = 86400
    }
    proton_dkim_authentication_1 = {
      zone_id = local.zone_id
      type    = "CNAME"
      name    = "dkim._domainkey.webdatabasesolutions.com"
      records = ["dkim._domainkey.alias.proton.me"]
      ttl     = 86400
    }
    proton_dkim_authentication_2 = {
      zone_id = local.zone_id
      type    = "CNAME"
      name    = "dkim02._domainkey.webdatabasesolutions.com"
      records = ["dkim02._domainkey.alias.proton.me"]
      ttl     = 86400
    }
    proton_dkim_authentication_3 = {
      zone_id = local.zone_id
      type    = "CNAME"
      name    = "dkim03._domainkey.webdatabasesolutions.com"
      records = ["dkim03._domainkey.alias.proton.me"]
      ttl     = 86400
    }
    proton_dmarc_authentication = {
      zone_id = local.zone_id
      type    = "TXT"
      name    = "_dmarc.webdatabasesolutions.com"
      records = ["v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s"]
      ttl     = 86400
    }
  }
}

resource "aws_route53_record" "main" {
  for_each = local.dns_records
  zone_id  = each.value.zone_id
  name     = each.value.name
  type     = each.value.type
  records  = each.value.records
  ttl      = each.value.ttl
}

