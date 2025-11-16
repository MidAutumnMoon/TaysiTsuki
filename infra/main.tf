terraform {
    required_providers {
        sops = {
            source = "carlpett/sops"
            version = "~> 1"
        }
        cloudflare = {
            source = "cloudflare/cloudflare"
            version = "~> 5"
        }
        tailscale = {
            source = "tailscale/tailscale"
            version = "~> 0"
        }
    }
}

data "sops_file" "token--cloudflare" {
    source_file = "../nixos/sops/token--cloudflare.sops.yml"
}

data "sops_file" "token--tailscale" {
    source_file = "./secrets/token--tailscale.sops.yml"
}

data "sops_file" "ip_addrs" {
    source_file = "./secrets/ip.sops.yml"
}

locals {
    secrets = {
        cloudflare = yamldecode( data.sops_file.token--cloudflare.raw )
        tailscale = yamldecode( data.sops_file.token--tailscale.raw )
    }
    ip_addrs = yamldecode(data.sops_file.ip_addrs.raw)
    tailnet = "fin-orfe.ts.net"
    im_418 = "418.im"
}
