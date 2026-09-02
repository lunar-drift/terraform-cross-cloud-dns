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
  type        = map(list(string))
  description = "A records: name -> list of IPv4 addresses (multiple = round-robin). '@' for apex."
  default     = {}
  # a_records = { "@" = ["203.0.113.10"], "www" = ["203.0.113.10", "203.0.113.11"] }
}

variable "cname_records" {
  type        = map(string)
  description = "CNAME records: name -> target."
  default     = {}

  validation {
    condition     = !contains([for k, v in var.cname_records : k], "@")
    error_message = "CNAME records cannot exist at the zone apex (@) — use A/ALIAS records there."
  }
  # cname_records = { "www" = "example.com", "blog" = "cname.vercel-dns.com" }
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
  description = "Define MX records: name -> list of mail exchangers. USe '@' for apex"
  default     = {}
  # Example:
  # mx_records = {
  #   "@" = [
  #     { priority = 10, value = "mx1.forward-email.net" },
  #     { priority = 20, value = "mx2.forward-email.net"},
  #   ]
  # }
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
