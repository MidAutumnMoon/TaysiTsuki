# RUNBOOK — state that cannot live in Nix or Terraform

Intended values for every knob that only exists in a web console or on a
client device. Check this file whenever those interfaces are touched; check
the consoles against it whenever this file is touched. Run `netcheck` after
any change on either side.

## Tailscale admin console

- **Machines → Remove** is manual (the provider only reads devices). When
  hardware is replaced or renamed, remove the old machine — a stale entry
  still advertises whatever it advertised, including exit node.
  Removed so far: `ren`.
- **"Use with exit node"** on nameservers: stays OFF, now owned per
  nameserver by `tailscale_dns_configuration` in `infra/tailscale.tf` (the
  console-only limitation is gone). With an exit node selected, the exit
  node resolves everything (that is the design); with none selected, split
  DNS serves `418.im` from `10.0.1.30`.
- **"Override local DNS"**: ON, owned by `tailscale_dns_configuration` in
  `infra/tailscale.tf`. Client DNS is captured into umi's sing-box listener
  (`100.113.193.81`); the console is only a fallback view.
- **umi must keep `--accept-dns=true`**: it also enables the quad-100
  forwarder that exit-node clients depend on (`false` made quad-100 answer
  SERVFAIL, which leaked clients to plaintext carrier DNS). uk-01 keeps
  `--accept-dns=false` (its DNS must not detour across the GFW).
- **OAuth client used by Terraform** (`infra/`): needs ACL write,
  Devices write with allowed tags `tag:phone` and `tag:server`, Routes write.
  Editing scopes does not rotate the key.
- Exit-node and subnet-route approvals are owned by
  `tailscale_device_subnet_routes` in `infra/tailscale.tf`; the console is
  only the fallback path.

## iPhone (Tailscale app)

- **Allow Local Network Access**: ON (Exit Nodes settings) — keeps home-LAN
  traffic direct instead of hairpinning through umi when an exit node is
  selected.
- **Use Tailscale DNS**: ON (default).

## OpenWrt router (not in this repository)

- DHCP reservation: `10.0.1.30` for umi's MAC — everything (dnscrypt binding,
  Caddy binding, split-DNS nameserver, lore records) depends on this.
- DHCP/RA advertise umi (`10.0.1.30` + ULA) as the LAN DNS server.
- wan6 inbound firewall: intended default-deny. Never verified from the
  inside; check when next logged into the router.

## Secrets

- `nixos/sops/token--cloudflare.sops.yml` — one token shared by Terraform
  and Caddy DNS-01. On the next rotation, consider minting two narrow tokens
  (zone/DNS edit for Terraform, DNS-01-only for Caddy) instead.
- Tailscale OAuth for Terraform: `infra/secrets/token--tailscale.sops.yml`.
- Terraform state encryption: `infra/secrets/encryption.sops` via
  `TF_ENCRYPTION` (see `.envrc`).
