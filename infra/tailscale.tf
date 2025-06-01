provider "tailscale" {
    oauth_client_id = local.secrets.tailscale.oauth_id
    oauth_client_secret = local.secrets.tailscale.oauth_secret
    tailnet = local.shared_with_nix.tailnet
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

resource "tailscale_dns_preferences" "main" {
    magic_dns = true
}

resource "tailscale_dns_split_nameservers" "teapot_split_dns" {
    domain = "418.im"
    nameservers = [
        "[${local.ts_devices.ren.ipv6}]:${local.shared_with_nix.dns_port}"
    ]
}

data "tailscale_devices" "all" { }

locals {
    # teapot_tailscale_suffix =
    # "some.ts12.ts.net" = { machine = "...", address = "::::" }
    ts_devices = {
        for dev in data.tailscale_devices.all.devices:
        # some.ts12.ts.net => some
        trimsuffix( dev.name, ".${local.shared_with_nix.tailnet}" )
        => {
            # The full name with ts.net
            fullname = dev.name
            ipv6 = [
                for addr in dev.addresses:
                addr if provider::assert::ipv6( addr )
            ][0]
            ipv4 = [
                for addr in dev.addresses:
                addr if provider::assert::ipv4( addr )
            ][0]
        }
    }
}

