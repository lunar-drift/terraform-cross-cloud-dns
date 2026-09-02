# --- terraform-cross-cloud-dns/example/providers.tf ---

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    dnsimple = {
      source  = "dnsimple/dnsimple"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = var.aws_assume_role_arn
    session_name = "TerraformSession"
  }
}

provider "dnsimple" {
  token    = var.dnsimple_token
  account  = var.dnsimple_account_id
  sandbox  = true
  prefetch = false
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}
