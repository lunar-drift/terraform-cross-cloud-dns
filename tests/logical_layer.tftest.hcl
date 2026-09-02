# tests/logical_layer.tftest.hcl
# Tier 1: unit tests for the logical layer.
# Providers are mocked — these tests validate pure HCL logic in locals.

mock_provider "aws" {}
mock_provider "dnsimple" {}
mock_provider "digitalocean" {}

# ==========================================================================
# Baseline inputs reused (mentally) across tests: two TXT values at "@",
# a round-robin pair at "www", one internal CNAME, one external CNAME,
# two MX entries at the apex, distinct per-subdomain TTL.
# ==========================================================================

variables {
  domain_name       = "example.com"
  default_ttl       = 3600
  per_subdomain_ttl = { "www" = 300 }

  dns_providers = ["aws", "dnsimple", "digitalocean"]

  txt_records = {
    "@" = [
      "v=spf1 include:_spf.google.com ~all",
      "google-site-verification=abc123",
    ]
  }

  a_records = {
    "@"   = ["203.0.113.10"]
    "www" = ["203.0.113.10", "203.0.113.11"]
  }

  cname_records = {
    "www"  = "lb.example.com"       # FQDN, same zone
    "blog" = "cname.vercel-dns.com" # external FQDN
  }

  mx_records = {
    "@" = [
      { priority = 10, value = "mx1.forward-email.net" },
      { priority = 20, value = "mx2.forward-email.net" },
    ]
  }
}

# --------------------------------------------------------------------------
# TXT: fan-out and grouping
# --------------------------------------------------------------------------

run "txt_flatten_fans_out_per_value" {
  command = plan

  assert {
    condition     = length(local.txt_logical) == 2
    error_message = "Two TXT values at '@' must flatten to two logical records, got ${length(local.txt_logical)}"
  }

  assert {
    condition     = alltrue([for r in local.txt_logical : r.name == "@"])
    error_message = "All flattened TXT records must carry name '@'"
  }

  assert {
    condition     = alltrue([for r in local.txt_logical : r.ttl == 3600])
    error_message = "TXT records without a TTL override must use default_ttl"
  }
}

run "txt_keys_are_deterministic_and_unique" {
  command = plan

  assert {
    condition     = length(keys(local.txt_map)) == 2
    error_message = "txt_map must hold one entry per TXT value"
  }

  assert {
    # Key uniqueness: md5 scheme must never collide for distinct values
    condition     = length(distinct([for r in local.txt_logical : r.key])) == length(local.txt_logical)
    error_message = "Every logical TXT record must produce a unique map key — md5(value) collisions break for_each addressing"
  }

  assert {
    # Round-trip: each logical record's value survives intact into the fan-out map
    condition     = alltrue([
      for r in local.txt_logical :
      local.txt_map[r.key].value == r.value
      ])
    error_message = "txt_map must round-trip each record's value under its own key"
  }
}

run "txt_aws_map_groups_same_name_into_one_rrset" {
  command = plan

  assert {
    condition     = length(keys(local.txt_map_aws)) == 1
    error_message = "Route53's one-RRset-per-(name,type) rule: both apex TXT values must collapse to a single record set"
  }

  assert {
    condition     = length(local.txt_map_aws["@"].values) == 2
    error_message = "The grouped AWS record must carry both TXT values"
  }

  assert {
    condition     = local.txt_map_aws["@"].ttl == 3600
    error_message = "Grouped AWS record inherits TTL from member records (recs[0])"
  }
}

# --------------------------------------------------------------------------
# A records: fan-out + round-robin grouping, per-subdomain TTL
# --------------------------------------------------------------------------

run "a_map_aws_groups_round_robin_by_name" {
  command = plan

  variables {
    dns_providers = ["aws"]
    a_records = {
      "www" = ["203.0.113.10", "203.0.113.11"]
    }
  }

  assert {
    condition = length(local.a_map_aws) == 1 && contains(keys(local.a_map_aws), "www")
    error_message = "A records must group per name for AWS, even with multiple IPs"
  }

  assert {
    condition     = length(local.a_map_aws["www"].values) == 2
    error_message = "www's RRset must carry both IPs (round-robin)"
  }

  assert {
    condition     = local.a_map_aws["www"].ttl == 300
    error_message = "per_subdomain_ttl['www'] = 300 must override default_ttl in the grouped map"
  }

  assert {
    condition     = alltrue([for v in local.a_map_aws["www"].values : !startswith(v, "\"")])
    error_message = "A-record values must NOT be jsonencoded — quoting is TXT-only"
  }
}

run "a_map_fans_out_per_ip" {
  command = plan

  variables {
    dns_providers = ["dnsimple"]
    a_records = {
      "www" = ["203.0.113.10", "203.0.113.11"]
    }
  }

  assert {
    condition     = length(local.a_map) == 2
    error_message = "Fan-out providers must receive one logical record per IP"
  }
}

# --------------------------------------------------------------------------
# CNAME: single-valued, FQDN rule, apex rejection (contract test)
# --------------------------------------------------------------------------

run "cname_targets_pass_through_unmodified" {
  command = plan

  variables {
    dns_providers = ["aws"]
    cname_records = {
      "blog" = "cname.vercel-dns.com"
    }
  }

  assert {
    condition     = local.cname_map["blog"].target == "cname.vercel-dns.com"
    error_message = "External FQDN targets must pass through unchanged (no normalization magic)"
  }
}

run "reject_cname_at_apex" {
  command = plan

  variables {
    dns_providers = ["dnsimple"]
    cname_records = { "@" = "bad.example.com" }
  }

  expect_failures = [var.cname_records]
}

# --------------------------------------------------------------------------
# MX: structured records, priority handling
# --------------------------------------------------------------------------

run "mx_logical_keeps_priority_separate" {
  command = plan

  variables {
    dns_providers = ["dnsimple", "digitalocean"]
    mx_records = {
      "@" = [
        { priority = 10, value = "mx1.alias.proton.me" },
        { priority = 20, value = "mx2.alias.proton.me" },
      ]
    }
  }

  assert {
    condition     = length(local.mx_logical) == 2
    error_message = "Two MX entries must flatten to two logical records"
  }

  assert {
    condition     = alltrue([for r in local.mx_logical : r.priority != null])
    error_message = "Priority must stay a separate attribute — DO renderer needs it unmerged"
  }
}

run "mx_aws_embeds_priority_in_wire_values" {
  command = plan

  variables {
    dns_providers = ["aws"]
    mx_records = {
      "@" = [
        { priority = 10, value = "mx1.alias.proton.me" },
        { priority = 20, value = "mx2.alias.proton.me" },
      ]
    }
  }

  assert {
    condition     = contains(keys(local.mx_map_aws), "@")
    error_message = "AWS must group MX per name — a single '@' record set should exist"
  }

  assert {
    condition     = contains(local.mx_map_aws["@"].values, "10 mx1.alias.proton.me") && contains(local.mx_map_aws["@"].values, "20 mx2.alias.proton.me")
    error_message = "AWS MX values must be '<priority> <target>' wire-format strings"
  }
}

# --------------------------------------------------------------------------
# Provider toggles: dns_providers gating flows into for_each keys
# --------------------------------------------------------------------------

run "toggle_gates_empty_maps" {
  command = plan

  variables {
    dns_providers = ["aws"] # dnsimple + digitalocean disabled
  }

  assert {
    condition     = local.deploy_aws && !local.deploy_dnsimple && !local.deploy_digitalocean
    error_message = "Only aws should be enabled"
  }
}

# --------------------------------------------------------------------------
# Inventory output: uniform schema across record types
# --------------------------------------------------------------------------

run "inventory_uniform_schema" {
  command = plan

  assert {
    condition     = contains(keys(output.dns_records.records), "TXT") && contains(keys(output.dns_records.records), "MX")
    error_message = "Inventory must expose TXT and MX record types"
  }

  assert {
    condition     = output.dns_records.domain == var.domain_name
    error_message = "Inventory must identify the domain"
  }

  assert {
    condition = length(output.dns_records.records) >= 4 && alltrue([
      for type, names in output.dns_records.records :
      alltrue([for name, rec in names : can(rec.values) && can(rec.ttl)])
    ])
    error_message = "Inventory must expose all four record types, each entry following the {values, ttl} schema"
  }
}