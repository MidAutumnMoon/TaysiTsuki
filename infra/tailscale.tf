provider "tailscale" {
  oauth_client_id     = local.secrets.tailscale.oauth_id
  oauth_client_secret = local.secrets.tailscale.oauth_secret
  tailnet             = local.tailnet
}

data "tailscale_devices" "all" {}

locals {
  # hostname -> device id, used for tagging and route approval.
  # the iphone's tailscale hostname is "localhost", not "iphone".
  __device_id = {
    for dev in data.tailscale_devices.all.devices :
    dev.hostname => dev.id
  }
}

resource "tailscale_acl" "main" {
  acl = jsonencode({
    # tagging devices through the API only works for tags that
    # have owners declared here
    tagOwners : {
      "tag:phone"  = ["autogroup:admin"]
      "tag:server" = ["autogroup:admin"]
    }
    acls : [
      # phone: exit nodes, umi's services (homelab names resolve
      # to 10.0.1.30 + the ULA -- autogroup:internet excludes
      # RFC1918 and ULA space, so the LAN prefixes need their
      # own entries), and tagged servers
      {
        action = "accept"
        users  = ["tag:phone"]
        ports = [
          "autogroup:internet:*",
          "10.0.1.0/24:*",
          "fda1:ac04:d4f6:0::/64:*",
          "tag:server:*",
        ]
      },
      # servers reach each other and the LAN subnet (uk-01's
      # split-dns path to 10.0.1.30:53)
      {
        action = "accept"
        users  = ["tag:server"]
        ports = [
          "10.0.1.0/24:*",
          "fda1:ac04:d4f6:0::/64:*",
          "tag:server:*",
        ]
      },
    ]
  })
}

# DNS is captured tailnet-wide: magic domains, 418.im, and -- via
# override_local_dns -- every other name flow into umi's sing-box dns
# listener (lore.machines.umi.tailnet_ip), which fronts dnscrypt and
# the proxy. Apply only after that listener is live, i.e. after the
# sing-box commit is built and switched (machine/ren/networking/proxy):
# pointing clients at a dead :53 takes the whole tailnet's dns down.
resource "tailscale_dns_configuration" "main" {
  magic_dns           = true
  override_local_dns = true

  # `use_with_exit_node` is now provider-managed per nameserver (the
  # old console-only limitation is gone); it stays at the default
  # (off): with an exit node selected, the exit node resolves.
  nameservers {
    address            = "100.113.193.81"
    use_with_exit_node = false
  }

  split_dns {
    domain = local.im_418
    nameservers {
      address            = "10.0.1.30"
      use_with_exit_node = false
    }
  }
}

resource "tailscale_device_tags" "phone" {
  device_id = local.__device_id["localhost"]
  tags      = ["tag:phone"]
}

resource "tailscale_device_tags" "umi" {
  device_id = local.__device_id["umi"]
  tags      = ["tag:server"]
}

resource "tailscale_device_tags" "uk-01" {
  device_id = local.__device_id["uk-01"]
  tags      = ["tag:server"]
}

# `routes` is authoritative: every route enabled for the device must
# be listed or the apply disables it, so umi's approved exit-node
# routes stay listed. The 10.0.1.0/24 approval requires the nix
# advertisement active first (machine/ren/networking/proxy/tproxy.nix).
resource "tailscale_device_subnet_routes" "umi" {
  device_id = local.__device_id["umi"]
  routes    = ["10.0.1.0/24", "0.0.0.0/0", "::/0"]
}
