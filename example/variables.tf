# --- terraform-cross-cloud-dns/example/variables.tf ---

# == Provider Variables ==
variable "aws_assume_role_arn" { type = string }
variable "dnsimple_token" { type = string }
variable "dnsimple_account_id" { type = string }
variable "do_token" { type = string }

# == CONFIGURATION VARIABLES ==
variable "domain_name" {
  type        = string
  description = "The zone this example deploys records into. Must already exist at providers where create_* = false."
}
