# RUNBOOK — state that cannot live in Nix or Terraform

Intended values for every knob that only exists in a web console or on a
client device. Check this file whenever those interfaces are touched; check
the consoles against it whenever this file is touched. Run `netcheck` after
any change on either side.

## Tailscale admin console

- **Machines → Remove** is manual (the provider only reads devices). When
  hardware is replaced or renamed, remove the old machine: a stale entry
  still advertises whatever it advertised, including exit node.
- **OAuth client used by Terraform** (`infra/`): needs ACL write, Devices
  write with allowed tags `tag:phone` and `tag:server`, Routes write.
  Editing scopes does not rotate the key.

## iPhone (Tailscale app)

- **Allow Local Network Access**: ON (Exit Nodes settings) — keeps home-LAN
  traffic direct instead of hairpinning through umi when an exit node is
  selected.
- **Use Tailscale DNS**: ON (default).

## OpenWrt router (not in this repository)

- DHCP reservation: `10.0.1.30` for umi's MAC — everything (dnscrypt
  binding, Caddy binding, split-DNS nameserver, lore records) depends on
  this.
- DHCP/RA advertise umi (`10.0.1.30` + ULA) as the LAN DNS server.
- wan6 inbound firewall: intended default-deny. Never verified from the
  inside; check when next logged into the router.

## Secrets

- `nixos/sops/token--cloudflare.sops.yml` — one token shared by Terraform
  and Caddy DNS-01. On the next rotation, consider minting two narrow
  tokens (zone/DNS edit for Terraform, DNS-01-only for Caddy).
- Tailscale OAuth for Terraform: `infra/secrets/token--tailscale.sops.yml`.
- Terraform state encryption: `infra/secrets/encryption.sops` via
  `TF_ENCRYPTION` (see `.envrc`).
