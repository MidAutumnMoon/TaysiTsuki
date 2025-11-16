provider "tailscale" {
    oauth_client_id = local.secrets.tailscale.oauth_id
    oauth_client_secret = local.secrets.tailscale.oauth_secret
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

resource "tailscale_dns_preferences" "main" {
    magic_dns = true
}

data "tailscale_devices" "all" { }

locals {
    # Transform the list of tailscale devices into a map of
    # hostname to ip address.
    __tailscale_devices = {
        for dev in data.tailscale_devices.all.devices:
        # `name` returned by api is "hostname.ts.net", trmming the tailnet
        # to get the hostname.
        trimsuffix( dev.name, ".${local.tailnet}" )
        => {
            # Store the full name in case.
            fullname = dev.name
            ipv6 = [
                for addr in dev.addresses:
                addr if can(regex("^[0-9a-fA-F:]+$", addr))
            ][0]
            ipv4 = [
                for addr in dev.addresses:
                addr if can(regex("^[0-9.]+$", addr))
            ][0]
        }
    }
}
