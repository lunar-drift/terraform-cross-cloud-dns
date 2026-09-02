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

variable "aws_assume_role_arn" {
  type = string
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = var.aws_assume_role_arn
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

# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" { type = string }

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}
