# -------- AWS Archive ------------
# resource "aws_route53_record" "a" {
#   for_each = local.deploy_aws ? var.a_records : {}
#
#   zone_id = aws_route53_zone.main[0].zone_id
#   name    = each.key == "@" ? var.domain_name : "${each.key}.${var.domain_name}"
#   type    = "A"
#   ttl     = var.per_subdomain_ttl[each.key]
#   records = [each.value]
# }
#
# resource "aws_route53_record" "cname" {
#   for_each = local.deploy_aws ? var.cname_records : {}
#
#   zone_id = aws_route53_zone.main[0].zone_id
#   name    = each.key == "@" ? var.domain_name : "${each.key}.${var.domain_name}"
#   type    = "CNAME"
#   ttl     = var.per_subdomain_ttl[each.key]
#   records = [each.value]
# }
# resource "aws_route53_record" "mx" {
#   # Safe unique keys created using string combinations from the flattened list
#   for_each = local.deploy_aws ? { for idx, record in local.mx_flattened : "${record.key}_${idx}" => record } : {}
#
#   zone_id = aws_route53_zone.main[0].zone_id
#   name    = each.value.key == "@" ? var.domain_name : "${each.value.key}.${var.domain_name}"
#   type    = "MX"
#   ttl     = var.per_subdomain_ttl[each.key]
#   records = ["${each.value.priority} ${each.value.value}"]
# }

# ==============================================================================
# 3. DIGITALOCEAN RESOURCES
# ==============================================================================
# resource "digitalocean_domain" "default" {
#   count = local.deploy_digitalocean ? 1 : 0
#   name  = var.domain_name
# }
#
# resource "digitalocean_record" "a" {
#   for_each = local.deploy_digitalocean ? var.a_records : {}
#
#   domain = digitalocean_domain.default[0].id
#   type   = "A"
#   name   = each.key
#   value  = each.value
#   ttl    = var.per_subdomain_ttl[each.key]
# }
#
# resource "digitalocean_record" "cname" {
#   for_each = local.deploy_digitalocean ? var.cname_records : {}
#
#   domain = digitalocean_domain.default[0].id
#   type   = "CNAME"
#   name   = each.key
#   value  = "${each.value}." # DigitalOcean handles fully-qualified target values natively
#   ttl    = var.per_subdomain_ttl[each.key]
# }
#
# resource "digitalocean_record" "txt" {
#   for_each = local.deploy_digitalocean ? var.txt_records : {}
#
#   domain = digitalocean_domain.default[0].id
#   type   = "TXT"
#   name   = each.key
#   value  = each.value
#   ttl    = var.per_subdomain_ttl[each.key]
# }
#
# resource "digitalocean_record" "mx" {
#   for_each = local.digitalocean ? { for idx, record in local.mx_flattened : "${record.key}_${idx}" => record } : {}
#
#   domain   = digitalocean_domain.default[0].id
#   type     = "MX"
#   name     = each.value.key
#   priority = each.value.priority
#   value    = "${each.value.value}."
#   ttl      = var.per_subdomain_ttl[each.key]
# }

# ---------dnsimple archive ---------
# resource "dnsimple_zone_record" "a" {
#   for_each = local.deploy_dnsimple ? var.a_records : {}
#
#   zone_name  = var.domain_name
#   type       = "A"
#   name       = each.key == "@" ? "" : each.key
#   value      = each.value
#   ttl        = var.per_subdomain_ttl[each.key]
# }
#
# resource "dnsimple_zone_record" "cname" {
#   for_each = local.deploy_dnsimple ? var.cname_records : {}
#
#   zone_name  = var.domain_name
#   type       = "CNAME"
#   name       = each.key
#   value      = each.value
#   ttl        = var.per_subdomain_ttl[each.key]
# }
#
#
# resource "dnsimple_zone_record" "mx" {
#   for_each = local.deploy_dnsimple ? { for idx, record in local.mx_flattened : "${record.key}_${idx}" => record } : {}
#
#   zone_name  = var.domain_name
#   type       = "MX"
#   name       = each.value.key == "@" ? "" : each.value.key
#   priority   = each.value.priority
#   value      = each.value.value
#   ttl        = var.per_subdomain_ttl[each.key]
# }


# # ------------------------------------------------------------------------------
# # 1. AWS ROUTE 53 MULTI-PROVIDER DEPLOYMENT
# # ------------------------------------------------------------------------------
# resource "aws_route53_zone" "primary" {
#   name = var.domain_name
# }
# #
# resource "aws_route53_record" "a" {
#   for_each = var.a_records
#   zone_id  = aws_route53_zone.primary.zone_id
#   name     = each.key == "@" ? var.domain_name : "${each.key}.${var.domain_name}"
#   type     = "A"
#   ttl      = 300
#   records  = [each.value]
# }
#
# resource "aws_route53_record" "cname" {
#   for_each = local.cname_records
#   zone_id  = aws_route53_zone.primary.zone_id
#   name     = "${each.key}.${var.domain_name}"
#   type     = "CNAME"
#   ttl      = 300
#   records  = [each.value]
# }
#
# resource "aws_route53_record" "txt" {
#   for_each = local.txt_records
#   zone_id  = aws_route53_zone.primary.zone_id
#   name     = each.key == "@" ? var.domain_name : "${each.key}.${var.domain_name}"
#   type     = "TXT"
#   ttl      = 300
#   records  = [rawencode(each.value)]
# }
#
# resource "aws_route53_record" "mx" {
#   zone_id = aws_route53_zone.primary.zone_id
#   name    = var.domain_name
#   type    = "MX"
#   ttl     = 300
#   records = [for r in local.mx_records : "${r.priority} ${r.value}"]
# }
#
# # ------------------------------------------------------------------------------
# # 2. DIGITALOCEAN MULTI-PROVIDER DEPLOYMENT
# # ------------------------------------------------------------------------------
# resource "digitalocean_domain" "default" {
#   name = var.domain_name
# }
#
# resource "digitalocean_record" "a" {
#   for_each = local.a_records
#   domain   = digitalocean_domain.default.id
#   type     = "A"
#   name     = each.key
#   value    = each.value
#   ttl      = 300
# }
#
# resource "digitalocean_record" "cname" {
#   for_each = local.cname_records
#   domain   = digitalocean_domain.default.id
#   type     = "CNAME"
#   name     = "${each.key}."
#   value    = each.value
#   ttl      = 300
# }
#
# resource "digitalocean_record" "txt" {
#   for_each = local.txt_records
#   domain   = digitalocean_domain.default.id
#   type     = "TXT"
#   name     = each.key
#   value    = each.value
#   ttl      = 300
# }
#
# resource "digitalocean_record" "mx" {
#   count    = length(local.mx_records)
#   domain   = digitalocean_domain.default.id
#   type     = "MX"
#   name     = "@"
#   priority = local.mx_records[count.index].priority
#   value    = local.mx_records[count.index].value
#   ttl      = 300
# }
#
# # ------------------------------------------------------------------------------
# # 3. DNSIMPLE MULTI-PROVIDER DEPLOYMENT
# # ------------------------------------------------------------------------------
# resource "dnsimple_zone_record" "a" {
#   for_each  = local.a_records
#   zone_name = var.domain_name
#   name      = each.key == "@" ? "" : each.key
#   value     = each.value
#   type      = "A"
#   ttl       = 300
# }
#
# resource "dnsimple_zone_record" "cname" {
#   for_each  = local.cname_records
#   zone_name = var.domain_name
#   name      = each.key
#   value     = each.value
#   type      = "CNAME"
#   ttl       = 300
# }
#
# resource "dnsimple_zone_record" "txt" {
#   for_each  = local.txt_records
#   zone_name = var.domain_name
#   name      = each.key == "@" ? "" : each.key
#   value     = each.value
#   type      = "TXT"
#   ttl       = 300
# }
#
# resource "dnsimple_zone_record" "mx" {
#   count     = length(local.mx_records)
#   zone_name = var.domain_name
#   name      = ""
#   value     = local.mx_records[count.index].value
#   type      = "MX"
#   priority  = local.mx_records[count.index].priority
#   ttl       = 300
# }
