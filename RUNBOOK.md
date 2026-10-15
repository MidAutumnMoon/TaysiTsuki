# RUNBOOK

This file holds state that cannot live in Nix or Terraform. It records
the intended values for every knob that only exists in a web console
or on a client device. Check this file whenever those interfaces are
touched, and check the consoles against it whenever this file is
touched. Run `netcheck` after any change on either side.

## Tailscale admin console

- **Machine removal is manual**: the Terraform provider only reads
  devices. When hardware is replaced or renamed, remove the old
  machine. A stale entry still advertises whatever it advertised,
  including exit node.
- **OAuth client used by Terraform**: its key lives in
  `infra/secrets/token--tailscale.sops.yml`. It needs ACL write,
  Devices write with allowed tags `tag:phone` and `tag:server`, and
  Routes write. Editing scopes does not rotate the key.

## iPhone (Tailscale app)

- **Allow Local Network Access**: ON, in the Exit Nodes settings. It
  keeps home-LAN traffic direct instead of hairpinning through umi
  when an exit node is selected.
- **Use Tailscale DNS**: ON. This is the default.

## OpenWrt router (not in this repository)

- DHCP reservation: `10.0.1.30` for umi's MAC. Everything else keys
  off this address, including the dnscrypt and Caddy bindings, the
  split-DNS nameserver, and the lore records.
- DHCP/RA advertisement: umi at `10.0.1.30` and the ULA as the LAN
  DNS server.
- wan6 inbound firewall: intended default-deny. Never verified from
  the inside. Check it when next logged into the router.

## Secrets

- `nixos/sops/token--cloudflare.sops.yml` is one token shared by
  Terraform and Caddy DNS-01. On the next rotation, consider minting
  two narrow tokens instead, one with zone/DNS edit for Terraform and
  one DNS-01-only for Caddy.
