terraform {
    required_providers {
        sops = {
            source = "carlpett/sops"
            version = "~> 1.2"
        }
        cloudflare = {
            source = "cloudflare/cloudflare"
            version = "~> 5.4"
        }
    }
}

data "sops_file" "token--cloudflare" {
    source_file = "../nixos/secrets/token--cloudflare.sops.yml"
}

locals {
    token = {
        cloudflare = yamldecode( data.sops_file.token--cloudflare.raw )
    }
}

