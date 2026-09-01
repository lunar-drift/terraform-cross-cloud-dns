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
    role_arn     = "arn:aws:iam::552162429610:role/LDAdminAccess"
    session_name = "TerraformSession"
  }
}

variable "dnsimple_token" {
  type = string
}

variable "dnsimple_account_id" {
  type = string
}

provider "dnsimple" {
  token    = var.dnsimple_token
  account  = var.dnsimple_account_id
  sandbox  = true
  prefetch = false
}
