locals {
    tailnet = nonsensitive( local.token.tailscale.tailnet )
}

provider "tailscale" {
    oauth_client_id = local.token.tailscale.oauth_id
    oauth_client_secret = local.token.tailscale.oauth_secret
    tailnet = local.tailnet
}

resource "tailscale_acl" "main" {
    acl = jsonencode( {
        acls: [ {
            action = "accept"
            users = [ "*" ]
            ports = [ "*:*" ]
        } ]
    } )
}

data "tailscale_devices" "all" { }
