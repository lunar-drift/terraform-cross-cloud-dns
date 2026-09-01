# --- terraform-cross-cloud-dns.variables ---
# TODO refactor a_records mx_records...
# TODO set up ttl at a per subdomain level... www is all
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

variable "a_records" {
  type        = map(string)
  description = "Define standard A records..."
  default     = {}
  # Example:
  # a_records = {
  #   "@"    = "192.0.2.1"
  #   "www"  = "192.0.2.2"
  #   "blog" = "192.0.2.3"
  # }
}
variable "cname_records" {
  type        = map(string)
  description = "Define standard CNAME records..."
  default     = {}
  # Example:
  # cname_records = {
  #   "www" = "xyz.cloudfront.amazon.com"
  # }
}

variable "txt_records" {
  type        = map(list(string))
  description = "Define TXT records..."
  default     = {}
  # Example:
  # txt_records = {
  #   "@" = [
  #     "v=spf1 include:_spf.google.com ~all",
  #     "google-site-verification=abc123",
  #   ]
  # }
}

variable "mx_records" {
  type        = map(list(object({ priority = number, value = string })))
  description = "Define MX records..."
  default     = {}
  # Example:
  # mx_records = {
  #   "@" = [
  #     { priority = 10, value = "mx1.alias.proton.me" },
  #     { priority = 20, value = "mx2.alias.proton.me"},
  #   ]
  # }
}

variable "domain_name" {
  type        = string
  description = "The primary domain name (e.g., example.com)"
  default     = "example.com"
}

variable "dnsimple_account_id" {
  type        = string
  description = "Your DNSimple Account ID"
  default     = "12345"
}

variable "per_subdomain_ttl" {}

