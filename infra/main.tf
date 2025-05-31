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
        tailscale = {
            source = "tailscale/tailscale"
            version = "~> 0.20"
        }
        assert = {
            source = "hashicorp/assert"
            version = "~> 0.16"
        }
    }
}

data "sops_file" "token--cloudflare" {
    source_file = "../nixos/secrets/token--cloudflare.sops.yml"
}

data "sops_file" "token--tailscale" {
    source_file = "./secrets/token--tailscale.sops.yml"
}

locals {
    token = {
        cloudflare = yamldecode( data.sops_file.token--cloudflare.raw )
        tailscale = yamldecode( data.sops_file.token--tailscale.raw )
    }
    sharedWithNix = nonsensitive(
        jsondecode( file( "../lore/shared.json" ) )
    )
}

