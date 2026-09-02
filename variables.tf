# --- terraform-cross-cloud-dns.variables ---

variable "dns_providers" {
  type        = list(string)
  description = "Which provider(s) records are being deployed to..."
  validation {
    condition = alltrue([
      for _ in var.dns_providers : contains(["aws", "dnsimple", "digitalocean"], _)
    ])
    error_message = "Invalid provider detected. The 'dns_providers' list can only contain 'aws', 'dnsimple', or 'digitalocean'."
  }
}

# a_records = { "@" = ["203.0.113.10"], "www" = ["203.0.113.10", "203.0.113.11"] }
variable "a_records" {
  type        = map(list(string))
  description = "A records: name -> list of IPv4 addresses (multiple = round-robin). '@' for apex."
  default     = {}
}

# cname_records = { "www" = "example.com", "blog" = "cname.vercel-dns.com" }
variable "cname_records" {
  type        = map(string)
  description = "CNAME records: name -> target."
  default     = {}

  validation {
    condition     = !contains([for k, v in var.cname_records : k], "@")
    error_message = "CNAME records cannot exist at the zone apex (@) — use A/ALIAS records there."
  }
  validation {
    condition     = alltrue([for v in values(var.cname_records) : strcontains(v, ".")])
    error_message = "CNAME targets must be fully-qualified domain names (e.g. \"svc.example.com\"), not bare labels."
  }
}

# txt_records = { "@" = ["v=spf1 include:_spf.google.com ~all", "google-site-verification=abc123"] }
variable "txt_records" {
  type        = map(list(string))
  description = "Define TXT records..."
  default     = {}
}

# mx_records = { "@" = [{ priority = 10, value = "mx1.forward-email.net" }, { priority = 20, value = "mx2.forward-email.net" }] }
variable "mx_records" {
  type        = map(list(object({ priority = number, value = string })))
  description = "Define MX records: name -> list of mail exchangers. USe '@' for apex"
  default     = {}
}

variable "domain_name" {
  type        = string
  description = "The primary domain name (e.g., example.com)"
  default     = ""
}

variable "per_subdomain_ttl" {
  type    = map(number)
  default = {}
}
variable "default_ttl" {
  type    = number
  default = 3600
}

variable "create_aws_route53_zone" {
  type = bool
  default = false
}

variable "create_digitalocean_domain" {
  type = bool
  default = false
}

variable "create_dnsimple_domain" {
  type = bool
  default = false
}

variable "aws_route53_zone_id" {
  type    = string
  default = ""
  validation {
    condition     = var.aws_route53_zone_id == "" || can(regex("^Z[0-9A-Z]{15,}$", var.aws_route53_zone_id))
    error_message = "aws_route53_zone_id must be either empty (lookup/data source path) or a Route53 zone ID like Z1D633PJN98FT9."
  }
  validation {
    condition     = !var.create_aws_route53_zone || var.aws_route53_zone_id == ""
    error_message = "aws_route53_zone_id must be empty when create_aws_route53_zone = true — the zone will be created by this module."
  }
  validation {
    condition     = var.create_aws_route53_zone || var.aws_route53_zone_id != ""
    error_message = "aws_route53_zone_id is required when create_aws_route53_zone = false (adopt mode)."
  }
}
