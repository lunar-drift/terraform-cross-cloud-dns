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
