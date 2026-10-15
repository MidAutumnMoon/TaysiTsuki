# Networking Architecture

`umi` (LAN interface `enp2s0`) is the tailnet's exit node, resolver, and
service hub; its configuration lives in `machine/ren/`. This document
records the design contracts, the current data flow, and the open watch
items.

## Scope

In scope: DNS on `umi` (dnscrypt-proxy, systemd-resolved, mDNS, Tailscale
DNS policy), iPhone exit-node traffic, nftables TPROXY and policy routing,
sing-box DNS and egress policy, Caddy listeners and service exposure,
Cloudflare and Tailscale state under `infra/`, and the `lore` values behind
service names and records.

Out of scope:

- `music.418.im`: `phia` is down after an HDD failure; back when the NAS is
  repaired.
- The router's DHCP, RA, and inbound firewall: configuration not in this
  repository; intended values live in RUNBOOK.md.

## Invariants

1. iPhone public traffic egresses through sing-box, never directly from
   `umi`.
2. DNS is not visible as plaintext on the carrier network. DNS inside the
   Tailscale tunnel already satisfies this (WireGuard encrypts the outer
   transport); upstream DNS from `umi` itself must use authenticated
   encryption (DNSCrypt, DoH, or DoT).
3. `umi` never falls back to plaintext WAN DNS when the proxy or an
   encrypted resolver fails.
4. LAN and tailnet service traffic does not depend on the sing-box process.
5. A sing-box failure may fail public access closed, but must not take
   down local DNS, Caddy, or direct tailnet service access.
6. A Tailscale failure must not stop a device already on home Wi-Fi from
   reaching LAN services when the client permits local-network access.
7. Every externally reachable listener has an explicit source/interface
   policy.
8. Packet classification happens before user space; sing-box is not needed
   to discover that a destination is local.
9. DNS, proxying, service publication, and authorization have separate
   owners.
10. Failure behavior is explicit and tested, not emergent from a stale
    route or an absent socket.

Public egress is fail closed: selected iPhone traffic must not fall back to
the ordinary Tailscale exit-node NAT path when sing-box is unavailable.

## Terminology

- LAN: `10.0.1.0/24` and its IPv6 prefixes (the ULA
  `fda1:ac04:d4f6:0::/64`).
- Tailnet: the Tailscale overlay, `100.64.0.0/10` and
  `fd7a:115c:a1e0::/48`.
- TPROXY: transparent interception that hands a packet to a local socket
  without rewriting its destination address or port.
- Fail closed: block rather than send directly.
- GUA: a globally routable IPv6 address.

## Ownership

| Concern | Owner | Notes |
|---|---|---|
| LAN interface, host proxy environment, resolved stub | `machine/ren/networking/module.nix` | `networking.proxy.default`; resolved `DNS=127.0.0.1`, empty `FallbackDNS`. |
| Local DNS records and recursive forwarding | `machine/ren/networking/dns/module.nix` | Cloaking rules generated from `lore`; dnscrypt-proxy serves them alone. |
| sing-box process, policy, secrets split | `machine/ren/networking/proxy/{module,policy}.nix` | Config generated at service start and gated by `sing-box check`. SOPS holds only the commercial outbounds and the clash secret. |
| iPhone interception, marks, policy routing, exit-node flags | `machine/ren/networking/proxy/tproxy.nix` | Device sets and network prefixes come from `lore`. |
| Runtime verification | `machine/ren/networking/netcheck/module.nix` | `netcheck` checks the DNS and exit-node invariants. |
| Service/domain inventory | `lore/module.nix`, `lore/options.nix` | Machine identity, service names, domains, ports. |
| Caddy base listener and unmatched-host policy | `nixos/services/caddy/module.nix` | Wildcard site with explicit 404 fallback; machines scope their own listeners and firewall openings. |
| Per-service Caddy handlers | Individual machine service modules | Merged into one wildcard virtual host. |
| Public DNS | `infra/cloudflare.tf` | Mail and the proxied uk-01 records only; no Tailscale-coupled records. |
| Tailnet ACL, tags, DNS capture, route approvals | `infra/tailscale.tf` | Tag-based grants; override local DNS ON with sing-box's listener as global nameserver; `418.im` split to `10.0.1.30`. |
| Secrets | SOPS | Commercial outbound secrets and API tokens. |
| DHCP/RA advertisement and edge firewall | Router | Not in this repository; intended values in RUNBOOK.md. |

`lore` stays an inventory, not a second runtime policy engine.

## Data flow

### iPhone public traffic

```text
iPhone application
  -> iOS Tailscale tunnel
  -> umi: tailscale0
  -> nft classifier (source match on the selected device)
       destination owned by umi / LAN / tailnet prefix: kernel bypass (counted)
       non-TCP/UDP: counted drop (fail closed)
       TCP/UDP: masked mark + TPROXY
  -> policy rule pref 5200 -> table 169: local default dev lo
  -> input firewall: accepts by interface, source, and mark
  -> sing-box :7891 transparent listener
  -> selected sing-box outbound
  -> internet
```

Non-intuitive details:

- TPROXY preserves the original destination port, so the input firewall
  must accept transparent packets by mark; port-based acceptance can never
  authorize them, and opening port 7891 does not help.
- The proxy mark lives in bits 8-15 (`0x0000ff00`), disjoint from
  Tailscale's `0x00ff0000` field, assigned by masked replacement. The
  policy-rule priority (5200) is explicit so it precedes Tailscale's
  table-52 rules in whatever order they install.
- Local, LAN, and tailnet destinations are bypassed in the kernel, so a
  sing-box process or listener failure cannot make a local service
  unreachable.

The selected source is the iPhone (addresses in `lore.machines.iphone`).

### iPhone and tailnet DNS

Client DNS is captured tailnet-wide (override local DNS, owned by
`infra/tailscale.tf`): every captured client resolves through sing-box's
DNS listener on `100.113.193.81:53`. It answers per class: `*.418.im` and
China names via dnscrypt on umi, foreign names via Cloudflare DoH through
the proxy, returning true answers so no curated or poisoned address is ever
dialed. Nothing leaves the tunnel in plaintext.

With an exit node selected the phone ignores split DNS entirely and sends
all names to quad-100 on umi, which forwards to the same listener. With no
exit node, split DNS serves `418.im` from `10.0.1.30` over the approved
subnet route; dnscrypt answers there identically.

### Host and LAN DNS

```text
umi or LAN client
  -> dnscrypt-proxy :53
      -> *.418.im names: exact-match cloaking rules, stable addresses from `lore`
      -> .local names: refused locally (block_undelegated)
      -> other queries: encrypted DoH upstreams
```

`systemd-resolved` is the host stub (`DNS=127.0.0.1`, empty
`FallbackDNS`, declared in `machine/ren/networking/module.nix`); local
records resolve to stable addresses, independent of mDNS discovery. mDNS is
a separate plane: avahi-daemon publishes `umi.local` and nss-mdns resolves
other hosts' `.local` names for local processes.

### Caddy

```text
client -> any address on umi:80/443 -> wildcard *.418.im site
       -> Host matcher -> loopback backend
       -> unmatched host: explicit 404
```

On umi, Caddy binds loopback, `10.0.1.30`, and the ULA; the firewall
accepts 80/443 only from LAN and tailnet sources. uk-01 keeps its public
wildcard binding for its proxied records. Some handlers add
`client_ip private_ranges`; that is defense in depth, not authorization.

## Symptom-to-cause guide

| Symptom | Highest-confidence cause | Distinguishing check |
|---|---|---|
| All public traffic and public DNS stop together | Tailscale path, sing-box process/listener, or selected outbound failed | Check Tailscale peer path, sing-box listener, and classifier counters separately. |
| Local Wi-Fi fails when Tailscale itself is broken | iPhone still routes/DNSes through the selected exit node | Enable local-network access or disable the exit node; the server cannot route around a broken client VPN. |
| `tailscale netcheck` says it uses the proxy | CLI inherited the shell proxy environment | Inspect `tailscaled.service` environment separately. |

## Verification matrix

| Scenario | DNS requirement | Routing requirement | Expected service result |
|---|---|---|---|
| Home Wi-Fi, Tailscale off or on without exit node | LAN resolver, encrypted upstream | Direct LAN | LAN services work. |
| Cellular, exit node selected | DNS stays inside Tailscale, then encrypted upstream | Public TCP/UDP via sing-box | Public proxy IP is observed; no direct fallback. |
| Cellular, exit node selected, arbitrary TCP port | Same | Marked input accepted independent of original port | Controlled connection reaches sing-box. |
| Cellular, unsupported public protocol | No DNS effect | Explicit counted policy | Deliberate drop by default. |
| sing-box stopped | LAN and umi DNS remain on dnscrypt; the phone's DNS dies with the global nameserver (accepted trade-off) | Local/tailnet bypass; public fails closed | LAN services work; `418.im` by direct IP works; public proxy traffic fails closed. |
| tailscaled stopped | LAN resolver remains available | Direct LAN only | Home LAN services work; remote tailnet access fails. |
| Encrypted upstream unavailable | Local zone remains available | No DNS fallback to WAN port 53 | Public DNS fails closed. |
| IPv6 temporary address rotates | No resolver reload storm | Stable listeners unchanged | No user-visible interruption. |

`netcheck` covers the host-side rows at runtime. Privacy proof needs a
packet capture on umi's WAN-facing interface: representative client queries
must not produce outbound TCP or UDP destination port 53. Availability
proof must exercise real applications and arbitrary ports, not only HTTPS
plus a successful DNS lookup.

## Emergency behavior

- Client-side recovery for LAN access: disable the exit node (or
  Tailscale) on the iPhone.
- Do not delete the TPROXY table to "restore" the ordinary exit-node NAT
  path: that path is unproven and sends traffic directly (privacy loss).
- A server-side emergency change must keep public traffic intercepted or
  explicitly dropped; apply it through a reversible NixOS test generation,
  not an unrecorded live rule edit.
- sing-box failure: public traffic fails closed; local/tailnet traffic and
  internal DNS continue.
- Resolver failure: local names may fail; no external plaintext fallback.
- Tailscale failure on cellular: remote access and proxying fail; no
  direct carrier fallback.
- Router failure: outside the guarantees of this host design.

## Watch items

- Delete `conf--sing.nix.sops` once the de-secreting has been stable for a
  comfortable period; it is unreferenced rollback material.
- Deduplicate the tailnet IP between `lore` and `infra/tailscale.tf` (via
  `default_secrets`) if it ever drifts.
- `phia` returns: move dnscrypt and Caddy off the desktop onto the NAS.
- HTTP/3 stays off in Caddy until quic over explicit multi-address
  listeners is understood: iOS caches the Alt-Svc advertisement, races dead
  QUIC against working h2, and renders blank pages.
- The LAN bypass covers the ULA prefix only (`lore.network.lan6`); LAN GUA
  destinations are deliberately treated as public (proxied or dropped).
  Revisit if a LAN client ever needs GUA reachability.
- The ordinary exit-node NAT forwarding path has never carried traffic;
  never treat it as a ready fallback.
- The next service change should land exposure as one declaration (process
  and backend in the service module, network exposure in one place,
  publication in Terraform) rather than more per-machine hand wiring.

### Tailscale transport

`tailscaled` reaches the control plane through the local proxy
(`HTTPS_PROXY` in the unit), which has kept a historical map-poll/DERP
instability at bay; its root cause was never confirmed. If it recurs:

- [ ] Capture root daemon logs during a real iPhone session.
- [ ] Use `tailscale ping` while the phone is awake on Wi-Fi and cellular
      to distinguish direct and DERP paths.
- [ ] Correlate map-poll health with network address changes and router
      state.
- [ ] Verify UDP reachability and NAT behavior at the router.
- [ ] Consider a closer/custom DERP only if repeated tests prove direct
      connectivity cannot be maintained and relay distance is the
      bottleneck.

Do not use proxy-rule changes to mask a Tailscale control-plane problem;
the two planes do not share the current packet path.

## Decision log

- Public egress stays proxied and fail closed; no plaintext DNS fallback
  for convenience, ever.
- Tailscale control health is a separate problem from the proxy path.
- Scope exposed ports at the host even where the router also filters.
- DNS records and Caddy host matching are not authorization; Tailscale
  ACLs or application auth own access control.
- Local records never point into `.local`; unicast DNS refuses `.local`
  through `block_undelegated`.
- DNSSEC validation is delegated to the encrypted upstreams; no local
  validator runs. Never publish a DS for `418.im`: the unsigned `.im`
  delegation is what keeps locally-synthesized answers validation-safe.
- Publication has exactly two modes: genuinely public services live on
  uk-01 behind Cloudflare-proxied records; private services are
  local-resolver names only. The public zone never carries
  Tailscale-coupled records.
- The away path rides the tailnet: exit node selected means umi resolves;
  deselected means split DNS over the subnet route. No
  Tailscale-independent away path (cloudflared was evaluated and rejected
  as primary: unreliable free-plan edge from China).
- Tailnet authorization is tag-based grants, not allow-all; exit-node use
  and service access are distinct rules.
- Unsupported public protocols from the phone are dropped (fail closed).
- The sing-box config split is fixed: structural policy plaintext in
  `policy.nix`; credentials, server addresses, provider domains, and ports
  stay in SOPS.
- sing-box's sniff action never rewrites the dial destination; poisoned or
  curated answers are healed at the resolver layer instead (per-class true
  answers, see the DNS flow above).
- No DNS-side ad blocking in sing-box's DNS engine (it silently NXDOMAIN'd
  duckduckgo.com for every captured client); route-level ad blocking
  stays.
- No geoip-based regional herding for bare-IP flows: they belong on the
  dual-stack default selector. A regional selector's default member must
  be dual-stack or the other family's destinations die.
- Caddy serves h1/h2 only (see watch items for HTTP/3).
- The exit-node resolver ignores split DNS by design: with an exit node
  selected, the phone's `418.im` queries ride the global nameserver too.
  sing-box down therefore costs the phone name resolution, accepted
  because public traffic is sing-box-dependent anyway. A second global
  nameserver was rejected: Tailscale round-robins rather than fails over,
  which would randomly serve curated answers.

Still open:

- Which services, if any, should be reachable through public GUAs.
- Whether a closer/custom DERP is justified by controlled transport tests.

## Sources

Repository sources:

- `machine/ren/networking/module.nix`
- `machine/ren/networking/dns/module.nix`
- `machine/ren/networking/proxy/module.nix`
- `machine/ren/networking/proxy/policy.nix`
- `machine/ren/networking/proxy/tproxy.nix`
- `machine/ren/networking/netcheck/module.nix`
- `nixos/services/caddy/module.nix`
- `nixos/services/avahi/module.nix`
- `lore/module.nix`
- `infra/cloudflare.tf`
- `infra/tailscale.tf`

External references:

- [Linux transparent proxy support](https://docs.kernel.org/networking/tproxy.html)
- [nftables chain priority and verdict behavior](https://wiki.nftables.org/wiki-nftables/index.php/Configuring_chains)
- [Tailscale DNS behavior](https://tailscale.com/docs/reference/dns-in-tailscale)
- [Tailscale exit nodes and local-network access](https://tailscale.com/docs/features/exit-nodes)
