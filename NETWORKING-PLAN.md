# Networking Architecture and Migration Plan

This document records the current networking design, the causal analysis behind
its failure modes, and a staged plan for improving it without weakening the
privacy properties required by the iPhone exit-node setup.

It is both a research memo and a roadmap. Facts under **Observed** were verified
from the evaluated NixOS configuration or live state. Items marked **Inference**
need a targeted runtime check before they become design assumptions.

## Scope

In scope:

- DNS on `umi`, including systemd-resolved, dnscrypt-proxy, mDNS, and
  Tailscale DNS policy.
- Tailscale exit-node traffic from the iPhone.
- nftables TPROXY and policy routing.
- sing-box DNS and egress policy.
- Caddy listeners and service exposure.
- Cloudflare and Tailscale state managed under `infra/`.
- The `lore` values used to construct service names and records.

The exit-node machine is `umi` (LAN interface `enp2s0`). Its configuration
lives in `machine/ren/`.

Out of scope:

- Navidrome availability. `phia` is intentionally down after an HDD failure, so
  `music.418.im` is expected to be unavailable until the NAS is repaired.
- Replacing the router. Its DHCP, RA, and inbound firewall state are relevant,
  but its configuration is not present in this repository.

## Required properties

The target design must preserve these invariants:

1. The iPhone's public internet traffic uses sing-box rather than leaving
   directly through `umi`.
2. DNS is not visible as plaintext on the carrier network.
3. `umi` does not silently fall back to plaintext WAN DNS when the proxy or an
   encrypted resolver fails.
4. LAN and tailnet service traffic does not depend on the sing-box process.
5. A sing-box failure may fail public internet access closed, but must not take
   down local DNS, Caddy, or direct tailnet service access.
6. A Tailscale failure must not prevent a device already on the home Wi-Fi from
   reaching LAN services when the client permits local-network access.
7. Every externally reachable listener has an explicit source/interface policy.
8. Packet classification happens before packets enter user space. sing-box
   should not be required merely to discover that a destination is local.
9. DNS, proxying, service publication, and authorization have separate owners.
10. Failure behavior is explicit and tested; it must not emerge accidentally
    from a stale route or an absent socket.

Unless changed deliberately, the public-egress policy is **fail closed**:
selected iPhone traffic must not fall back to the ordinary Tailscale exit-node
NAT path when sing-box is unavailable.

## Terminology

- **LAN**: the home network attached to `enp2s0`, currently
  `10.0.1.0/24` plus its IPv6 prefixes.
- **Tailnet**: the Tailscale overlay, including `100.64.0.0/10` and this
  tailnet's `fd7a:115c:a1e0::/48` IPv6 range.
- **Exit node**: `umi` when it accepts a client's default routes and sends that
  client's public traffic onward.
- **TPROXY**: transparent socket interception. It sends traffic to a local
  transparent socket without rewriting the original destination address or
  port.
- **DNS hijack**: sing-box intercepts DNS packets addressed to another resolver
  and answers or forwards them according to its own DNS rules.
- **Fail closed**: public traffic is blocked rather than sent directly when the
  required proxy path is unavailable.
- **Local destination**: an address owned by `umi` itself. This is distinct from
  another device on the LAN.
- **Split horizon**: the same DNS name intentionally has different answers on
  LAN and public resolvers.
- **GUA**: a globally routable IPv6 address.

A raw UDP DNS packet inside a Tailscale tunnel is not plaintext on the carrier
network: WireGuard encrypts the outer transport between the iPhone and the
Tailscale peer or DERP relay. A separate requirement applies after the packet
reaches `umi`: upstream DNS from `umi` should also use authenticated encryption
such as DNSCrypt, DoH, or DoT.

## Ownership today

| Concern | Current owner | Notes |
|---|---|---|
| LAN interface and host proxy environment | `machine/ren/networking/module.nix` | Sets `networking.proxy.default`, networkd policy, and the resolved stub settings. |
| Local DNS records and recursive forwarding | `machine/ren/networking/dns/module.nix` | Generates cloaking rules from `lore`; dnscrypt-proxy serves them alone. |
| sing-box process and runtime generation | `machine/ren/networking/proxy/module.nix` | Evaluates an encrypted Nix expression at service start. |
| iPhone interception and exit-node flags | `machine/ren/networking/proxy/tproxy.nix` | Interception sets and network prefixes come from `lore`. |
| Service/domain inventory | `lore/module.nix`, `lore/options.nix` | Mixes machine identity, service names, domains, and ports. |
| Caddy base listener and firewall openings | `nixos/services/caddy/module.nix` | Wildcard site and certificate; on umi the listeners bind loopback/LAN/ULA addresses only. |
| Per-service Caddy handlers | Individual machine service modules | Merged into one wildcard virtual host. |
| Public DNS | `infra/cloudflare.tf` | Only genuinely public records: mail and the proxied uk-01 services. No Tailscale-coupled records. |
| Tailnet ACL, tags, split DNS, subnet routes | `infra/tailscale.tf` | Tag-based grants; `418.im` split DNS to `10.0.1.30`; umi's routes approved. |
| MagicDNS settings | Admin console + `tailscale_dns_preferences` | Override off; no global resolvers; `Use with exit node` stays off (see RUNBOOK). |
| Secrets | SOPS | The sing-box private configuration is opaque until runtime evaluation. |
| DHCP/RA DNS advertisement and inbound edge policy | Router | Not represented in this repository; reservation and intended values recorded in RUNBOOK. |

## Current data flow

### iPhone public traffic

```text
iPhone application
  -> iOS Tailscale tunnel
  -> umi: tailscale0
  -> nft source match for the iPhone
  -> mark 0x00690000
  -> TPROXY transparent socket selection
  -> policy route table 169: local default dev lo
  -> NixOS input firewall
  -> sing-box :7891
  -> selected sing-box outbound
  -> internet
```

The source sets currently contain:

```text
IPv4 100.117.156.47
IPv6 fd7a:115c:a1e0::4901:9c2f
```

Observed counters show the selected traffic consumed locally and re-originated
by sing-box: the TPROXY counter was nonzero while the IPv4 `FORWARD` jump into
`ts-forward` and both `ts-postrouting` masquerade rules saw no packets. The
ordinary exit-node forwarding path is therefore not a proven fallback.

### iPhone DNS

With an exit node selected, the phone uses umi as its resolver for all
domains, ignoring split DNS entirely. quad-100 forwards to the tailnet's
global nameserver — sing-box's DNS listener on `100.113.193.81:53` — which
answers per class: `*.418.im` and China names via dnscrypt on umi, foreign
names via Cloudflare DoH through the proxy (true answers, so no curated or
poisoned address is ever dialed). Nothing leaves the tunnel in plaintext.

With no exit node selected, split DNS routes `418.im` to `10.0.1.30` over
the approved subnet route; all other names use the client's network resolver
(the carrier on cellular, umi itself on home Wi-Fi). Both modes are verified
from the phone on cellular.

### Host and LAN DNS

```text
umi or LAN client
  -> dnscrypt-proxy :53
      -> *.418.im names: exact-match cloaking rules, stable addresses from `lore`
      -> .local names: refused locally by the explicit block_undelegated setting
      -> other queries: encrypted DoH upstreams
```

`systemd-resolved` is the host stub and forwards to `127.0.0.1`; its
`DNS=127.0.0.1`, explicit empty `FallbackDNS`, and `MulticastDNS=no` are
declared in `machine/ren/networking/module.nix`. Local records resolve
directly to stable addresses, independent of mDNS discovery. mDNS remains a
separate plane: avahi-daemon publishes `umi.local`, and nss-mdns resolves
other hosts' `.local` names for local processes; it is the only mDNS
resolver on the host.

### Local service access from the iPhone

Today, an iPhone packet can be intercepted before sing-box later decides that
its destination is private or on the tailnet. Consequently, the packet still
depends on all of these being healthy:

```text
Tailscale -> nft/PBR -> sing-box process -> sing-box direct route -> service
```

A destination being classified as `Outbound Direct` inside sing-box does not
make the path independent of sing-box.

### Caddy

```text
client -> any address on umi:80/443 -> wildcard *.418.im site
       -> Host matcher -> loopback backend
```

On umi, Caddy binds loopback, `10.0.1.30`, and the ULA; the firewall accepts
80/443 only from LAN and tailnet sources. (uk-01 keeps its public wildcard
binding for its proxied records.) Some handlers use
`client_ip private_ranges`; `peerban` and `wpad` do not. The wildcard site has
no explicit final rejection, so an unmatched hostname can receive an empty
HTTP 200 response.

## Confirmed flaws and causal consequences

### 1. The NixOS input firewall filters TPROXY traffic by original port

TPROXY preserves the original destination. After policy routing delivers the
packet locally, it traverses the input hook with that destination port intact.

The current NixOS firewall permits only:

```text
TCP: 22, 53, 80, 443, 7890, 7891
UDP: 53, 443, 5353, 7890, 7891, 41641
```

Therefore a new intercepted connection to public TCP 5223, TCP 993, TCP/UDP
853, or an arbitrary application port can be dropped before sing-box receives
it. TCP/UDP 53, 80, and 443 can work, creating application-dependent rather
than total failure.

Opening port 7891 does not authorize transparent traffic: the packet's original
destination port is still present. Port 7891 only permits a direct connection
whose real destination is `umi:7891`.

The Tailscale `ts-input` accept does not override this. nftables accepts are not
final when another base chain at the same or a later hook can still drop the
packet.

### 2. Non-TCP/UDP packets are marked before protocol selection

Every packet from the selected source enters `handle_tproxy`. The first rule
sets the mark; only the next rule checks for TCP or UDP. ICMP and other
protocols therefore retain the proxy mark without being assigned to a
transparent socket. Policy table 169 then routes them locally.

This is an accidental blackhole, not an explicit privacy policy. Public
non-TCP/UDP traffic must instead have one deliberate outcome:

- drop it for strict fail-closed behavior; or
- return it to ordinary exit-node forwarding if direct egress is acceptable.

The default plan is an explicit, counted drop for public unsupported protocols.
Local and tailnet traffic must be classified before this drop so local ICMP
continues to work.

### 3. Locality is decided too late

LAN, `umi`-local, and tailnet destinations are not excluded before the TPROXY
jump. sing-box may route them directly, but only after they have crossed the
user-space dependency boundary.

Consequence: a sing-box process or listener failure can make a physically local
service unavailable.

### 4. The custom mark shares Tailscale's mark field

The custom rule uses mask `0x00ff0000`, the same field used by Tailscale for
values such as `0x00040000` and `0x00080000`.

The rule also uses bitwise OR:

```text
0x00690000 | 0x00040000 = 0x006d0000
```

`0x006d0000` does not match the policy rule expecting
`0x00690000/0x00ff0000`.

The custom inet prerouting chain and the iptables-nft mangle prerouting chain
also have the same priority. Evaluation order for base chains with identical
hook and priority is not guaranteed. The custom classifier needs a disjoint
mark mask, masked assignment rather than OR, and an explicit priority after
existing mark restoration but before the NixOS reverse-path filter at
`mangle + 10`.

### 5. Policy-rule ordering is implicit

The custom `ip rule add` does not specify a priority, so the kernel
auto-allocates one and the result depends on which rules exist at start time.
The rule has been observed at 32765 (after Tailscale's table-52 lookup, so
tailnet destinations could be routed by table 52 first) and at 5209 (before
it). Either ordering can be a workable bypass, but it is an incidental result
of rule order rather than an encoded policy.

Local and tailnet bypasses should be explicit in nftables, and the custom
policy rule should have an explicit stable priority.

### 6. Failure mode is implicit

`tproxy-route.service` requires sing-box but has no stop action, no readiness
check, and no explicit state transition. The route and nft rules can remain
effective when the sing-box listener is gone.

Persistent interception can be valid for fail-closed public traffic, but it
must be represented as policy rather than as cleanup accidentally missing from
a service.

The desired states are:

| State | Public traffic | Local/tailnet traffic | DNS |
|---|---|---|---|
| Proxy active | TPROXY to sing-box | Kernel bypass | Encrypted path |
| Proxy degraded | Explicit drop or closed TPROXY socket | Kernel bypass | Internal DNS remains available; no plaintext fallback |
| Policy deliberately disabled | Explicit administrative choice | Normal routing | A separately verified resolver policy |

### 7. sing-box listeners are scoped by firewall only

The mixed (`:7890`) and TPROXY (`:7891`) inbounds bind wildcard addresses on
both stacks. The firewall confines them to LAN and tailnet sources, but the
listeners themselves carry no address policy: the sing-box configuration is
encrypted, so rebinding waits on the de-secreting work.

### 8. Runtime sing-box policy is difficult to audit

The installed sing-box is 1.14.0. Its generated runtime policy differs from the
provided decoded `sing-box-config`: live logs contain a materially larger China
ruleset. The supplied artifact also contains suspicious selector membership and
an apparent US/China ruleset copy error (the US ruleset reuses the China
geosite), and an "Others" route rule with empty matchers shadows the geo rules.

Nix should own non-secret routing, listener, DNS, and selector policy. SOPS
keeps credentials, server addresses, provider domains, and ports. The
generated JSON must be checked with `sing-box check` before replacing the
running process.

### 9. Tailscale transport has an independent health problem

Pre-reinstall, the daemon showed:

- `Self.Online=false` while the daemon was running.
- An inability to synchronize with the coordination server.
- Repeated two-minute map-poll timeouts.
- 379 `derp-2 does not know about peer ..., removing route` messages over 24
  hours.
- Direct HTTPS connectivity to the control-plane endpoint still succeeded.

The custom TPROXY chain only handles packets arriving on `tailscale0`; it does
not intercept host-originated tailscaled control traffic. `tailscaled.service`
now carries `HTTPS_PROXY` through the local proxy, and the exit-node
advertisement synchronized immediately after that landed; the failure has not
recurred. The control/DERP path remains a separate failure domain to watch.

## Symptom-to-cause guide

| Symptom | Highest-confidence cause | Distinguishing check |
|---|---|---|
| HTTPS works but an app using another port fails | NixOS input firewall drops TPROXY packet by original port | Compare controlled TCP 443 with TCP 8443/5223 and UDP 443 with another UDP port. |
| Ping fails while HTTPS works | Non-TCP packet marked before protocol check | Trace one ICMP packet from the iPhone. |
| All public traffic and public DNS stop together | Tailscale path, sing-box process/listener, or selected outbound failed | Check Tailscale peer path, sing-box listener, and branch counters separately. |
| A service on `umi` fails when sing-box stops | No pre-TPROXY local-destination bypass | Connect to both `umi` LAN and Tailscale addresses while sing-box is stopped. |
| Another LAN host fails when sing-box stops | No pre-TPROXY LAN bypass | Connect directly to a controlled LAN address. |
| Local Wi-Fi fails when Tailscale itself is broken | iPhone still routes/DNSes through the selected exit node | Enable local-network access or disable the exit node; the server cannot route around a broken client VPN. |
| `tailscale netcheck` says it uses the proxy | CLI inherited shell proxy environment | Inspect `tailscaled.service` environment separately. |
| DNS answer differs by test tool | Different local, public, MagicDNS, or hijacked resolver path | Record the actual resolver path, not only the returned address. |

## Target architecture

### Separate planes

```text
LAN clients
  |-- DNS ----------------> stable resolver on umi
  |                           |-- local authoritative records
  |                           `-- encrypted recursive upstream
  |
  `-- HTTPS -------------> Caddy on stable LAN address
                              `-- loopback backends

Tailnet clients
  |-- service traffic ----> umi/other peer directly over Tailscale
  `-- exit-node traffic --> umi tailscale0
                               |-- local/tailnet destination: kernel bypass
                               |-- DNS to umi resolver: local encrypted resolver
                               `-- public TCP/UDP: TPROXY -> sing-box -> proxy

Tailscale daemon ---------> control/DERP directly, never through sing-box
Caddy certificate client -> direct unless an explicit dependency is justified
```

### Packet-classification policy

The following is policy pseudocode, not a drop-in nft file:

```nft
packet arrives on tailscale0
  if source is not a selected proxy client:
      return

  if destination belongs to umi:
      return

  if destination is an intentional LAN or tailnet prefix:
      return

  if protocol is not TCP or UDP:
      explicit counted drop  # default fail-closed choice

  assign a dedicated proxy mark using masked replacement
  TPROXY to the transparent sing-box listener
```

Important details:

- Classify local/tailnet destinations before unsupported protocols so local
  ICMP and service traffic still work.
- `fib daddr type local` can express addresses owned by `umi`; explicit sets
  should cover other LAN and tailnet destinations.
- Use a mark mask disjoint from Tailscale's `0x00ff0000` field.
- Give the nft chain and `ip rule` explicit priorities.
- Add counters for every terminal branch: local bypass, LAN bypass, tailnet
  bypass, TPROXY, unsupported drop.
- The NixOS input firewall must accept packets assigned to the transparent
  socket based on interface, source, and mark rather than original destination
  port.
- Remove direct firewall access to 7891. A transparent packet does not need the
  original destination port to be 7891.

### Proxy lifecycle

The proxy path has three explicit states:

```text
ACTIVE:
  local/tailnet bypasses are installed
  public TCP/UDP is sent to a verified transparent listener

DEGRADED:
  local/tailnet bypasses remain
  public traffic is explicitly dropped or remains on a closed TPROXY path
  encrypted internal DNS remains available
  no direct WAN fallback occurs

DISABLED BY ADMINISTRATOR:
  interception changes only through an explicit operation
  direct-exit behavior is not implied by stopping sing-box
```

Recommended service behavior:

- Generate and validate the sing-box config before activation.
- Install a fail-closed public drop before exit traffic can flow, then replace
  that drop with TPROXY only after the listener is ready.
- Use `Restart=on-failure` for sing-box.
- Couple policy state and process readiness. For fail-closed semantics, stopping
  sing-box transitions public traffic to an explicit drop, not direct routing.
- A planned direct-exit mode, if ever wanted, is a separately tested state with
  its own encrypted DNS path.

### Listener and authorization policy

| Service | Listener policy | Firewall/authorization policy |
|---|---|---|
| dnscrypt-proxy | Loopback and stable LAN address, optional Tailscale address | LAN sources; selected tailnet sources only if served there. |
| sing-box mixed `7890` | Loopback or explicit stable LAN address | Intended sources only; authenticate if the network is not fully trusted. |
| sing-box TPROXY `7891` | Transparent listener | No broad direct input opening; only marked transparent traffic accepted. |
| Caddy `80/443` | Stable LAN and Tailscale addresses; public address only when intentional | Per-interface firewall plus Tailscale ACL and explicit host policy. |
| Tailscale UDP `41641` | Tailscale daemon | WAN as required for direct connectivity. |
| SSH `22` | Intended management addresses | Explicit management sources or tailnet policy. |

Caddy should use explicit handlers and an explicit unmatched-host rejection.
`client_ip` checks are defense in depth; Tailscale ACLs or application auth own
access control.

### Configuration ownership target

| Fact | Target owner |
|---|---|
| Whether a service runs, its loopback backend, and its Caddy handler | The service's Nix module |
| Stable machine addresses and shared domain identifiers | Nix/`lore` inventory |
| Exposure class (`lan`, `tailnet`, `public`) | One Nix declaration consumed by listener/firewall policy |
| Local DNS records | Nix resolver configuration, derived only from intentional active records |
| Public DNS records | OpenTofu under `infra/` |
| Tailscale grants, MagicDNS, provider-supported DNS settings | OpenTofu under `infra/` |
| Console-only Tailscale settings | Minimized and recorded until provider support exists |
| Proxy and DNS routing policy | Non-secret Nix source |
| Proxy endpoint credentials and private keys | SOPS only |
| DHCP/RA advertisement and edge firewall | Versioned router configuration or an explicit external runbook |

`lore` should remain an inventory rather than a second runtime policy engine. A
large universal service generator is not required. The next service change
should have one obvious home: process and backend in its service module,
network exposure in one exposure declaration, public publication in Terraform.

## Migration plan

The plan is landed. The classifier repair, the fail-closed lifecycle (config
check gate, automatic restart, nft-coupled rule install), Caddy hardening
(scoped listeners, explicit 404 for unmatched hosts, per-handler source
matchers, wpad removed), and the sing-box de-secreting (plaintext policy in
`policy.nix`, SOPS reduced to provider endpoints, tailnet DNS served by
sing-box on `100.113.193.81:53`) are all live and verified — the proof items
below were exercised: arbitrary ports from the phone, the kill-test matrix,
`sing-box check` gating, and reddit/HN/Discord/DuckDuckGo loading from
cellular with clean resolver paths.

Remaining items are events, not work:

- **Delete `conf--sing.nix.sops`** once the de-secreting has been stable for
  a comfortable period (it is unreferenced rollback material).
- **Deduplicate the tailnet IP** between `lore` and `infra/tailscale.tf` via
  the `default_secrets` mechanism if it ever drifts.
- **phia returns**: move dnscrypt and Caddy off the desktop onto the NAS.
- **HTTP/3**: re-enable in Caddy only after quic-on-multi-bind is understood
  (see the decision log).

### Tailscale transport watch

The control plane now reaches the coordination servers through the local
proxy and the map-poll failure has not recurred. If it does:

- [ ] Capture root daemon logs during a real iPhone session.
- [ ] Use `tailscale ping` while the phone is awake on Wi-Fi and cellular to
      distinguish direct and DERP paths.
- [ ] Correlate map-poll health with network address changes and router state.
- [ ] Verify UDP reachability and NAT behavior at the router.
- [ ] Consider a closer/custom DERP only if repeated tests prove that direct
      connectivity cannot be maintained and relay distance is the bottleneck.

Do not use proxy-rule changes to mask a Tailscale control-plane problem; the two
planes do not share the current packet path.

## Verification matrix

| Scenario | DNS requirement | Routing requirement | Expected service result |
|---|---|---|---|
| iPhone on home Wi-Fi, Tailscale off | LAN resolver, encrypted upstream | Direct LAN | LAN services work. |
| Home Wi-Fi, Tailscale on, no exit | Local DNS must not be overridden unexpectedly | Direct LAN/tailnet | LAN services work. |
| Home Wi-Fi, exit node selected, local access allowed | No carrier concern; resolver path documented | LAN destinations bypass public TPROXY | LAN services work if sing-box is stopped. |
| Cellular, exit node selected | DNS remains inside Tailscale then encrypted upstream | Public TCP/UDP uses sing-box | Public proxy IP is observed; no direct fallback. |
| Cellular, exit node selected, arbitrary TCP port | Same | Marked input accepted independent of original port | Controlled connection reaches sing-box. |
| Cellular, unsupported public protocol | No DNS effect | Explicit counted policy | Deliberate drop by default. |
| sing-box stopped | LAN and umi-host DNS remain on dnscrypt; the phone's DNS dies with the exit-node resolver (the tailnet global nameserver IS sing-box — verified trade-off) | Local/tailnet bypass; public fails closed | LAN services work; `418.im` by direct IP works; public proxy traffic fails closed. |
| tailscaled stopped | LAN resolver remains available | Direct LAN only | Home LAN services work; remote tailnet access fails. |
| encrypted upstream unavailable | Local zone remains available | No DNS fallback to WAN port 53 | Public DNS fails closed. |
| IPv6 temporary address rotates | No resolver reload storm | Stable listeners unchanged | No user-visible interruption. |

Privacy proof should include a packet capture on `umi`'s WAN-facing interface:
representative client queries must not produce outbound TCP or UDP destination
port 53. Availability proof must exercise actual applications and arbitrary
ports, not only HTTPS and a successful DNS lookup.

## Emergency behavior

### Current configuration

If sing-box fails before the classifier repair lands, the safest client-side
recovery for LAN access is to disable the exit node or Tailscale on the
iPhone. Deleting the complete TPROXY table would enable an untested ordinary
exit-node path. Do not use that as a privacy-preserving fallback.

A server-side emergency change that preserves privacy must add local/tailnet
bypasses ahead of TPROXY while keeping public traffic intercepted or explicitly
dropped. Apply it through a reversible NixOS test generation rather than an
unrecorded live rule edit.

### Target configuration

- Proxy process failure: public traffic fails closed; local/tailnet and internal
  DNS continue.
- Resolver failure: local names may fail if the resolver itself is down; no
  external plaintext fallback occurs.
- Tailscale failure on cellular: remote access and proxying fail; no direct
  carrier fallback is assumed.
- Tailscale failure on home Wi-Fi: the client disables the broken exit path or
  uses local-network access; LAN services continue directly.
- Router failure: outside the guarantees of this host design.

## Research memo

### Observed runtime state

- `umi` LAN IPv4: `10.0.1.30` (router DHCP reservation). Router DHCP/RA
  advertises `umi` itself (`10.0.1.30` plus the ULA) as the LAN resolver.
- dnscrypt-proxy is the only `:53` listener: `10.0.1.30`, the ULA
  `fda1:ac04:d4f6:0:4af3:17ff:fe19:6f16`, and loopback, on TCP and UDP.
- `systemd-resolved` global DNS is the declared `127.0.0.1` with an empty
  `FallbackDNS` list. avahi-daemon publishing plus nss-mdns is the only mDNS
  stack.
- `umi` Tailscale addresses: `100.113.193.81` and
  `fd7a:115c:a1e0::cb3b:c152`. The exit node is advertised and approved;
  the `10.0.1.0/24` subnet route is advertised and approved. The iPhone
  (`100.117.156.47`, `fd7a:115c:a1e0::4901:9c2f`) uses the exit node and
  both DNS modes are verified from cellular.
- Tailnet policy: tag-based grants (`tag:phone`, `tag:server`), MagicDNS on
  with override off, no global resolvers, split DNS `418.im -> 10.0.1.30`.
- `umi` is configured with `--advertise-exit-node`, `--advertise-routes` for
  the LAN, and `--accept-dns=false`; the last affects only `umi`'s client
  resolver.
- sing-box version: 1.14.0. Tailscale version in the unit: 1.102.3.
- Policy table 169 contains IPv4 and IPv6 `local default dev lo` routes; the
  Nix reverse-path filter explicitly accepts the custom proxy mark.
- `tailscaled.service` reaches the control plane via `HTTPS_PROXY` through
  the local proxy; Caddy inherits `networking.proxy.envVars`.
- sing-box's mixed and TPROXY listeners bind wildcard addresses; the
  firewall confines their ports to LAN and tailnet sources.
- Firewall: 22/53/80/443/7890 accepted only from LAN and tailnet ranges;
  Caddy binds loopback/LAN/ULA. A `netcheck` command verifies the DNS and
  exit-node invariants.

### Relevant history

- `b656f6fa`: introduced the TPROXY path.
- `45e06f1b`: added `--accept-dns=false`.
- `aa97b0d9`: disabled an attempted Tailscale split-DNS configuration.
- `442fb10f`: removed the commented split-DNS resource.

The history shows an incremental design rather than one coherent ownership
model: exit-node routing, resolver policy, and service discovery were adjusted
separately, leaving their combined failure behavior implicit.

### Important uncertainties

- Router inbound IPv6 firewall policy is not in the repository (intended
  default-deny; see RUNBOOK). DHCP advertisement of the `umi` resolver was
  observed live; RA details were not.
- The TPROXY LAN bypass covers the ULA prefix only; LAN GUA destinations are
  deliberately treated as public (proxied or dropped). No current client
  needs them.
- The encrypted live sing-box configuration differs from the supplied decoded
  artifact; exact rule semantics must be checked against generated JSON.
- No controlled arbitrary-port test was completed from the iPhone (awaits the
  classifier repair).
- No fail-open standard exit-node path has been proven. IPv4 forwarding into
  `ts-forward` was zero, IPv6 saw only 12 packets, and neither Tailscale
  masquerade rule saw a packet; this path must not be treated as a ready
  fallback.
- The root cause of the historical Tailscale map-poll/DERP instability is
  unconfirmed, though proxying the control plane has kept it at bay.

## Decision log

Decisions already supported by the evidence:

- Keep iPhone public egress proxied.
- Keep DNS encrypted; never add plaintext fallback for convenience.
- Keep public egress fail closed until a different privacy policy is explicitly
  chosen.
- Move local and tailnet bypasses before TPROXY.
- Repair NixOS input acceptance for marked transparent packets.
- Give the custom mark and rule priority explicit ownership.
- Keep local DNS records independent of sing-box.
- Treat Tailscale control health as a separate problem.
- Scope exposed ports at the host even if the router also filters them.
- Do not treat DNS records or Caddy host matching as authorization.
- dnscrypt-proxy alone owns the resolver role via exact-match cloaking rules.
- Local records never point into `.local`; unicast DNS refuses `.local`
  through the explicit `block_undelegated` setting.
- DNSSEC validation is delegated to the encrypted upstreams; no local
  validator runs. Never publish a DS for `418.im`: the unsigned `.im`
  delegation is what keeps locally-synthesized answers validation-safe.
- Publication has exactly two modes: genuinely public services live on uk-01
  behind Cloudflare-proxied records; private services are local-resolver
  names only. The public zone never carries Tailscale-coupled records.
- The away path rides the tailnet: exit node selected means umi resolves;
  exit node deselected means split DNS over the subnet route. No
  Tailscale-independent away path (cloudflared was evaluated and rejected as
  primary: unreliable free-plan edge from China).
- Tailnet authorization is tag-based grants, not allow-all; exit-node use and
  service access are distinct rules.
- Unsupported public protocols from the phone are dropped (fail closed).
- sing-box de-secreting moves only structural policy to Nix; credentials,
  server addresses, provider domains, and ports stay encrypted.
- Console-only state is recorded in `RUNBOOK.md`, not remembered.
- sing-box's sniff action never rewrites the dial destination (removed
  upstream, no replacement); poisoned or curated answers are therefore healed
  at the RESOLVER layer instead: the tailnet's global nameserver is sing-box's
  own DNS engine, which returns real answers per class (China via dnscrypt,
  foreign via Cloudflare-through-the-proxy).
- No DNS-side ad blocking in sing-box's engine (it silently NXDOMAIN'd
  duckduckgo.com for every captured client); route-level ad blocking stays.
- No geoip-based regional herding for bare-IP flows: they fall to the
  dual-stack default selector. A regional selector's default member must be
  dual-stack or the other family's destinations die.
- Caddy serves h1/h2 only; HTTP/3 stays off until quic over explicit
  multi-address listeners is understood (the failure mode was iOS caching the
  Alt-Svc advertisement, racing dead QUIC, and rendering blank pages).
- The exit-node resolver ignores split DNS ("regardless of configuration"):
  with an exit node selected, the phone's `418.im` queries ride the global
  nameserver too. sing-box down therefore costs the phone name resolution —
  accepted, because public traffic is sing-box-dependent anyway. A second
  global nameserver was rejected: Tailscale round-robins rather than fails
  over, which would randomly serve curated answers.

Decisions still open:

- Which services, if any, should be reachable through public GUAs.
- Whether a closer/custom DERP is justified by controlled transport tests.

## Sources

Repository sources:

- `machine/ren/networking/module.nix`
- `machine/ren/networking/dns/module.nix`
- `machine/ren/networking/proxy/module.nix`
- `machine/ren/networking/proxy/tproxy.nix`
- `machine/ren/networking/proxy/dashboard.nix`
- `nixos/services/caddy/module.nix`
- `nixos/services/avahi/module.nix`
- `lore/module.nix`
- `lore/options.nix`
- `infra/cloudflare.tf`
- `infra/tailscale.tf`

External references:

- [Linux transparent proxy support](https://docs.kernel.org/networking/tproxy.html)
- [nftables chain priority and verdict behavior](https://wiki.nftables.org/wiki-nftables/index.php/Configuring_chains)
- [Tailscale DNS behavior](https://tailscale.com/docs/reference/dns-in-tailscale)
- [Tailscale exit nodes and local-network access](https://tailscale.com/docs/features/exit-nodes)
- [sing-box TPROXY inbound](https://sing-box.sagernet.org/configuration/inbound/tproxy/)
- [sing-box DNS rules](https://sing-box.sagernet.org/configuration/dns/rule/)
- [sing-box route rules](https://sing-box.sagernet.org/configuration/route/rule/)
- [Caddy `bind`](https://caddyserver.com/docs/caddyfile/directives/bind)
- [Caddy request matchers](https://caddyserver.com/docs/caddyfile/matchers)
