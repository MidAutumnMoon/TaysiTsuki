# Networking Architecture

`umi` is the tailnet's exit node, resolver, and service hub. This
document holds the standing contracts, the ownership decisions, and
the open watch items.

## Terminology

- LAN: `10.0.1.0/24` plus the ULA `fda1:ac04:d4f6:0::/64`.
- Tailnet: the Tailscale overlay, `100.64.0.0/10` and
  `fd7a:115c:a1e0::/48`.
- TPROXY: transparent interception that hands a packet to a local
  socket without rewriting its destination address or port.
- Fail closed: block rather than send directly.
- GUA: a globally routable IPv6 address.

## Invariants

1. iPhone public traffic egresses through sing-box, never directly
   from `umi`.
2. DNS is not visible as plaintext on the carrier network. DNS inside
   the Tailscale tunnel already satisfies this because WireGuard
   encrypts the outer transport. Upstream DNS from `umi` itself must
   use authenticated encryption, meaning DNSCrypt, DoH, or DoT.
3. `umi` never falls back to plaintext WAN DNS when the proxy or an
   encrypted resolver fails.
4. LAN and tailnet service traffic does not depend on the sing-box
   process.
5. A sing-box failure may fail public access closed, but must not
   take down local DNS, Caddy, or direct tailnet service access.
6. A Tailscale failure must not stop a device already on home Wi-Fi
   from reaching LAN services when the client permits local-network
   access.
7. Every externally reachable listener has an explicit
   source/interface policy.
8. Packet classification happens before user space. sing-box is not
   needed to discover that a destination is local.
9. DNS, proxying, service publication, and authorization have
   separate owners.
10. Failure behavior is explicit and tested, not emergent from a
    stale route or an absent socket.

## Ownership

| Concern | Owner |
|---|---|
| LAN interface, host proxy environment, resolved stub | `machine/ren/networking/module.nix` |
| Local DNS records and recursive forwarding | `machine/ren/networking/dns/module.nix` |
| sing-box process, policy, secrets split | `machine/ren/networking/proxy/{module,policy}.nix` |
| iPhone interception, marks, policy routing, exit-node flags | `machine/ren/networking/proxy/tproxy.nix` |
| Runtime verification | `machine/ren/networking/netcheck/module.nix` |
| Service/domain inventory | `lore/module.nix`, `lore/options.nix` |
| Caddy base listener and unmatched-host policy | `nixos/services/caddy/module.nix` |
| Per-service Caddy handlers | Individual machine service modules |
| Public DNS | `infra/cloudflare.tf` |
| Tailnet ACL, tags, DNS capture, route approvals | `infra/tailscale.tf` |
| Secrets | SOPS |

The router's DHCP/RA advertisement and edge firewall are not in this
repository. Their intended values live in RUNBOOK.md.

`lore` stays an inventory, not a second runtime policy engine.

## Symptom-to-cause guide

| Symptom | Highest-confidence cause | Distinguishing check |
|---|---|---|
| All public traffic and public DNS stop together | Tailscale path, sing-box process/listener, or selected outbound failed | Check Tailscale peer path, sing-box listener, and classifier counters separately. |
| Local Wi-Fi fails when Tailscale itself is broken | iPhone still routes/DNSes through the selected exit node | Enable local-network access or disable the exit node. The server cannot route around a broken client VPN. |
| `tailscale netcheck` says it uses the proxy | CLI inherited the shell proxy environment | Inspect `tailscaled.service` environment separately. |

## Emergency behavior

- For client-side LAN recovery, disable the exit node or Tailscale on
  the iPhone.
- Do not delete the TPROXY table to "restore" the ordinary exit-node
  NAT path. That path has never carried traffic and sends everything
  directly, which loses privacy.
- A server-side emergency change must keep public traffic intercepted
  or explicitly dropped. Apply it through a reversible NixOS test
  generation, not an unrecorded live rule edit.

## Verification

`netcheck` covers the host-side contracts at runtime. The privacy
contract additionally needs a packet capture on umi's WAN-facing
interface. Representative client queries must not produce outbound
TCP or UDP destination port 53. Availability must be exercised with
real applications and arbitrary ports, not only HTTPS plus a
successful DNS lookup.

## Watch items

- Delete `conf--sing.nix.sops` once the de-secreting has been stable
  for a comfortable period. It is unreferenced rollback material.
- Deduplicate the tailnet IP between `lore` and `infra/tailscale.tf`
  (via `default_secrets`) if it ever drifts.
- When `phia` returns, move dnscrypt and Caddy off the desktop onto
  the NAS.
- The LAN bypass covers the ULA prefix only (`lore.network.lan6`).
  LAN GUA destinations are deliberately treated as public, proxied or
  dropped. Revisit if a LAN client ever needs GUA reachability.
- Which services, if any, should be reachable through public GUAs
  remains open.
- The next service change should land exposure as one declaration,
  with process and backend in the service module, network exposure in
  one place, and publication in Terraform, rather than more
  per-machine hand wiring.

### Tailscale transport

`tailscaled` reaches the control plane through the local proxy, which
has kept a historical map-poll/DERP instability at bay. The root
cause was never confirmed. If it recurs:

- [ ] Capture root daemon logs during a real iPhone session.
- [ ] Use `tailscale ping` while the phone is awake on Wi-Fi and
      cellular to distinguish direct and DERP paths.
- [ ] Correlate map-poll health with network address changes and
      router state.
- [ ] Verify UDP reachability and NAT behavior at the router.
- [ ] Consider a closer/custom DERP only if repeated tests prove
      direct connectivity cannot be maintained and relay distance is
      the bottleneck.

Do not use proxy-rule changes to mask a Tailscale control-plane
problem. The two planes do not share the current packet path.

## Decision log

- Scope exposed ports at the host even where the router also filters.
- DNS records and Caddy host matching are not authorization. Tailscale
  ACLs or application auth own access control.
- Local records never point into `.local`, because unicast DNS refuses
  `.local` through `block_undelegated`.
- DNSSEC validation is delegated to the encrypted upstreams, and no
  local validator runs. Never publish a DS for `418.im`. The unsigned
  `.im` delegation is what keeps locally-synthesized answers
  validation-safe.
- Publication has exactly two modes. Genuinely public services live on
  uk-01 behind Cloudflare-proxied records, and private services are
  local-resolver names only. The public zone never carries
  Tailscale-coupled records.
- The away path rides the tailnet. With the exit node selected, umi
  resolves. Deselected, split DNS serves over the subnet route. There
  is no Tailscale-independent away path. Cloudflared as primary was
  rejected because its free-plan edge is unreliable from China.
- The exit-node resolver ignores split DNS by design. A second global
  nameserver would round-robin rather than fail over, serving curated
  answers at random.
- sing-box's sniff action never rewrites the dial destination. Poisoned
  or curated answers are healed at the resolver layer by returning
  per-class true answers.
- No DNS-side ad blocking in sing-box's DNS engine, because it
  silently NXDOMAIN'd duckduckgo.com for every captured client.
  Route-level ad blocking stays.

## References

- [Linux transparent proxy support](https://docs.kernel.org/networking/tproxy.html)
- [nftables chain priority and verdict behavior](https://wiki.nftables.org/wiki-nftables/index.php/Configuring_chains)
- [Tailscale DNS behavior](https://tailscale.com/docs/reference/dns-in-tailscale)
- [Tailscale exit nodes and local-network access](https://tailscale.com/docs/features/exit-nodes)
