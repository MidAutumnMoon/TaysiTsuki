# Networking Architecture and Migration Plan

This document records the current networking design, the causal analysis behind
its failure modes, and a staged plan for improving it without weakening the
privacy properties required by the iPhone exit-node setup.

It is both a research memo and a roadmap. Facts under **Observed** were verified
from the evaluated NixOS configuration or live state. Items marked **Inference**
need a targeted runtime check before they become design assumptions.

## Scope

In scope:

- DNS on `umi`, including systemd-resolved, CoreDNS, dnscrypt-proxy, mDNS, and
  Tailscale DNS policy.
- Tailscale exit-node traffic from the iPhone.
- nftables TPROXY and policy routing.
- sing-box DNS and egress policy.
- Caddy listeners and service exposure.
- Cloudflare and Tailscale state managed under `infra/`.
- The `lore` values used to construct service names and records.

The exit-node machine is `umi` (LAN interface `enp2s0`). Its configuration
still lives in `machine/ren/` and deploys via the `ren.local` target.

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
| LAN interface and host proxy environment | `machine/ren/networking/module.nix` | Sets `networking.proxy.default` and networkd policy. |
| Local DNS records and recursive forwarding | `machine/ren/networking/dns/module.nix` | Generates records from `lore`; combines CoreDNS, avahi2dns, and dnscrypt-proxy. |
| sing-box process and runtime generation | `machine/ren/networking/proxy/module.nix` | Evaluates an encrypted Nix expression at service start. |
| iPhone interception and exit-node flags | `machine/ren/networking/proxy/tproxy.nix` | Hard-codes the selected iPhone Tailscale addresses. |
| Service/domain inventory | `lore/module.nix`, `lore/options.nix` | Mixes machine identity, service names, domains, and ports. |
| Caddy base listener and firewall openings | `nixos/services/caddy/module.nix` | Wildcard site, wildcard certificate, global port openings. |
| Per-service Caddy handlers | Individual machine service modules | Merged into one wildcard virtual host. |
| Public DNS | `infra/cloudflare.tf` | Includes public records pointing at Tailscale IPv6 addresses; the tailnet service records are keyed to the device hostname `ren`, which breaks once `umi` rejoins the tailnet. |
| Tailnet ACL and MagicDNS | `infra/tailscale.tf` | ACL is currently allow-all; only MagicDNS preference is declared. |
| Tailscale global resolvers and `Use with exit node` | Admin console | Not fully represented by the current Terraform resources. |
| Secrets | SOPS | The sing-box private configuration is opaque until runtime evaluation. |
| DHCP/RA DNS advertisement and inbound edge policy | Router | Not represented in this repository. |

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

The live TPROXY counter showed 120,530 packets and 18,619,239 bytes. The IPv4
`FORWARD` jump into `ts-forward` saw no packets (IPv6 saw 12), and the inner
`ts-postrouting` masquerade rule saw no packets in either family. The outer
`POSTROUTING` jumps were nonzero, so traffic reached postrouting but none used
Tailscale's marked masquerade path. This is consistent with the selected
iPhone TCP/UDP traffic being consumed locally and re-originated by sing-box
rather than using ordinary exit-node forwarding and masquerading.

### iPhone DNS

Observed packets included DNS from the iPhone to Cloudflare resolver addresses:

```text
iPhone -> encrypted Tailscale tunnel -> 1.1.1.1:53
       -> nft TPROXY -> sing-box :7891
       -> sing-box hijack-dns
       -> sing-box DNS rule and selected upstream
```

The destination visible in the packet is therefore not necessarily the server
that answers the query.

Tailscale documents that an exit-node client normally uses the exit node as its
resolver. A nameserver is retained while using an exit node only when its
**Use with exit node** setting is enabled. **Inference:** the observed
Cloudflare-destination traffic, together with the global resolver list received
from the coordination server, indicates that this setting is enabled. Root
`tailscale debug netmap` or the admin console must confirm it.

### Host and LAN DNS

```text
umi or LAN client
  -> CoreDNS :53
      -> generated local record file
      -> .local queries: avahi2dns :9102
      -> other queries: dnscrypt-proxy [::1]:9099
      -> encrypted upstream DNS
```

`systemd-resolved` is the host stub and forwards to CoreDNS. It is not the
source of local service records. Its `DNS=127.0.0.1` comes from the running
generation's `resolved.conf` and is set by no module in this repository.

The generated record file is configured as a root-zone file but contains an
unrelated `example.com.` SOA. Several application names are CNAMEs to `.local`
names, so ordinary application DNS depends on mDNS discovery and current
interface addresses.

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

Caddy binds to `::`, which is currently a dual-stack wildcard listener. The
host firewall accepts 80/443 globally. Some handlers use
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

### 7. DNS transport and DNS policy are conflated

The iPhone sends toward Cloudflare, Tailscale encrypts the transport to `umi`,
and sing-box answers according to a different policy. This satisfies part of
the privacy requirement but obscures ownership and makes packet captures
misleading.

The cleaner statement is: the iPhone uses `umi` as its exit-node resolver;
`umi` owns local names and uses an authenticated encrypted upstream. If
sing-box requires special remote DNS for routing, that is a separate public
proxy-DNS policy, not the owner of LAN service records.

### 8. CoreDNS binds dynamic addresses and reloads excessively

CoreDNS binds the whole `enp2s0` interface, taking a snapshot of all its
addresses. The interface carries a stable GUA plus a router-advertised ULA,
and its address set changes over time. An address monitor reloads CoreDNS once
for every address event.

The resolver should bind named stable addresses. The monitor and reload loop
then become unnecessary.

### 9. Host firewall exposure is broad

The supplied root ruleset confirms that these ports are accepted without
source or interface restrictions:

```text
TCP: 22, 53, 80, 443, 7890, 7891
UDP: 53, 443, 5353, 7890, 7891, 41641
```

CoreDNS and the proxy listen on public GUAs as well as LAN addresses. External
reachability still depends on the router, but the host firewall itself provides
no final source restriction. This is a confirmed P0 host-policy defect, not a
DNS-record concern.

### 10. Tailscale access policy is allow-all

`infra/tailscale.tf` permits every user to every destination and port. Caddy
source matchers and absent public DNS records are not authorization boundaries.
Exit-node use, service access, and administration need distinct Tailscale
permissions.

### 11. Runtime sing-box policy is difficult to audit

The installed sing-box is 1.14.0. Its generated runtime policy differs from the
provided decoded `sing-box-config`: live logs contain a materially larger China
ruleset. The supplied artifact also contains suspicious selector membership and
an apparent US/China ruleset copy error.

Nix should own non-secret routing, listener, DNS, and selector policy. SOPS
should contain only credentials and private endpoints. The generated JSON must
be checked with `sing-box check` before replacing the running process.

### 12. Tailscale transport had an independent health problem

Observed state included:

- `Self.Online=false` while the daemon was running.
- An inability to synchronize with the coordination server.
- Repeated two-minute map-poll timeouts.
- 379 `derp-2 does not know about peer ..., removing route` messages over 24
  hours.
- Direct HTTPS connectivity to the control-plane endpoint still succeeded.

The custom TPROXY chain only handles packets arriving on `tailscale0`; it does
not intercept host-originated tailscaled control traffic. The active
`tailscaled.service` also did not inherit the HTTP proxy environment. The
control/DERP issue is therefore a separate failure domain.

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

### DNS architecture

Target roles:

1. A stable resolver on `umi` owns LAN records and caching.
2. Local records use direct A/AAAA data, not CNAMEs to `.local`.
3. Upstream internet DNS uses DNSCrypt, DoH, or DoT without plaintext fallback.
4. Tailscale transports iPhone DNS to `umi`; the carrier sees only encrypted
   tunnel traffic.
5. sing-box may own proxy-specific public DNS routing, but never LAN service
   discovery.

CoreDNS plus dnscrypt-proxy can satisfy these roles if their boundary is made
explicit; replacing them with Unbound is optional, not a goal by itself. Do not
swap resolver implementations merely to reduce the process count.

Preferred client policy while using the exit node:

```text
iPhone -> Tailscale exit-node DNS -> umi resolver -> encrypted upstream
```

This removes the misleading `1.1.1.1` destination/hijack relationship. Migrate
only after the `umi` resolver is proven from an exit-node client. Until then,
keep the working DNS hijack while fixing packet classification around it.

For home Wi-Fi independence:

- Router DHCP/RA advertises the stable `umi` resolver.
- Tailscale's global override must not force home clients away from the LAN
  resolver.
- The iPhone must allow local-network access while an exit node is selected.
- If the Tailscale tunnel itself is broken while still selected, the client must
  disable the exit node or have an on-demand policy that does so. No server-side
  architecture can make traffic escape a broken client VPN safely.

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
| CoreDNS or replacement | Loopback, stable LAN address, optional Tailscale address | LAN sources; selected tailnet sources only if served there. |
| dnscrypt-proxy | Loopback only | No inbound firewall opening. |
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

Make one behavioral change per activation. Preserve the previous boot generation
and use a test activation before making it persistent.

### Phase 0: establish a reproducible baseline

- [ ] Save `nft list ruleset`, IPv4/IPv6 rules, and table 169 routes.
- [ ] Save `tailscale status --json`, `tailscale dns status`, and current admin
      console DNS settings.
- [ ] Inspect the exact generated sing-box JSON and run `sing-box check` on it.
- [ ] Record current Clash selector choices.
- [ ] While the iPhone is awake, record whether its Tailscale path is direct or
      relayed.
- [ ] Test controlled TCP destinations on 443 and a non-allowlisted port.
- [ ] Test controlled UDP destinations on 443 and a non-allowlisted port.
- [ ] Test public and local ICMP separately.
- [ ] Record resolver answers on home Wi-Fi, cellular, with no exit node, and
      with `umi` selected as exit node.

Proof required before proceeding: the test distinguishes a Tailscale transport
failure, Nix input drop, sing-box listener failure, and proxy-outbound failure.

### Phase 1: close broad host exposure

- [ ] Remove direct TCP/UDP firewall openings for 7891.
- [ ] Restrict 7890 to intended interfaces and source prefixes.
- [ ] Restrict port 53 to LAN and explicitly selected tailnet sources.
- [ ] Restrict 80/443 to intended interfaces; retain public GUA access only for
      deliberately public services.
- [ ] Restrict SSH to its management plane.
- [ ] Confirm router IPv6 ingress policy.

Rollback: reactivate the previous NixOS generation. Do not add ad-hoc permanent
rules outside Nix.

Proof: scan from an allowed LAN client, an allowed tailnet client, and an
untrusted reachable source. Each listener must have an explicit expected
result.

### Phase 2: repair the TPROXY classifier without changing DNS policy

- [ ] Add pre-TPROXY bypasses for addresses owned by `umi`.
- [ ] Add intentional LAN and tailnet bypass prefixes.
- [ ] Classify TCP/UDP before setting the proxy mark.
- [ ] Explicitly drop or pass unsupported public protocols; default to drop.
- [ ] Allocate a mark outside Tailscale's mask.
- [ ] Replace mark OR with deterministic masked assignment.
- [ ] Set explicit nft and policy-rule priorities.
- [ ] Add a NixOS input rule accepting marked transparent traffic independent
      of original destination port.
- [ ] Add branch counters.
- [ ] Keep the existing sing-box DNS hijack and outbound choices unchanged in
      this phase.

Proof:

- Arbitrary controlled TCP and UDP ports reach sing-box.
- Local and tailnet destinations do not increment the TPROXY counter.
- Unsupported public protocols hit their explicit counter.
- Stopping sing-box leaves direct IP connectivity to local and tailnet services
  available while public traffic remains closed. Name-based access may still
  depend on the current hijacked DNS path until Phases 4 and 5.

### Phase 3: make fail-closed lifecycle explicit

- [ ] Define active, degraded, and administratively disabled states.
- [ ] Validate sing-box configuration before changing the active listener.
- [ ] Install an explicit public drop before exit traffic can flow.
- [ ] Atomically replace that drop with TPROXY only after listener readiness.
- [ ] Restart sing-box automatically after unexpected failure.
- [ ] Ensure degraded state cannot fall through to standard Tailscale NAT.
- [ ] Provide one explicit administrative transition if direct exit mode is
      ever required.

Proof: kill sing-box during active traffic. Existing and new public flows must
fail without revealing `umi`'s direct public egress, while local/tailnet paths
continue.

Transitional limitation: until Phases 4 and 5 move client DNS onto the stable
resolver path, stopping sing-box may still break name resolution from the
iPhone even though direct local/tailnet IP connectivity survives.

### Phase 4: stabilize local DNS

- [ ] Bind CoreDNS to loopback and deliberate stable addresses rather than the
      entire interface snapshot.
- [ ] Remove the interface-address reload watcher.
- [ ] Replace the incoherent root file with a proper local-zone or hosts-style
      record source.
- [ ] Replace `.local` CNAME chains with direct stable A/AAAA records.
- [ ] Keep mDNS only for genuine link-local discovery.
- [ ] Verify dnscrypt-proxy upstream encryption and remove every plaintext
      fallback.
- [ ] Decide whether DNSSEC is validated locally or by a trusted encrypted
      upstream; document the choice.
- [ ] Confirm router DHCP and RA advertise the stable resolver.

CoreDNS plus dnscrypt-proxy is an acceptable end state. Evaluate Unbound only if
it removes real policy complexity or provides required local validation.

Proof:

- Capture `enp2s0` while issuing representative queries; no outbound TCP/UDP 53
  may appear.
- Local records resolve while sing-box is stopped.
- Internet records either resolve through authenticated encryption or fail
  closed.
- IPv6 privacy-address rotation does not reload or rebind the resolver.

### Phase 5: make the Tailscale DNS path truthful

- [ ] Verify exit-node DNS against the stabilized resolver on `umi`.
- [ ] Disable Cloudflare `Use with exit node` for a single client test.
- [ ] Confirm that the carrier-facing path remains only Tailscale tunnel traffic.
- [ ] Disable global DNS override on home Wi-Fi if it bypasses the LAN resolver.
- [ ] Remove unnecessary global resolver configuration after all client modes
      pass.
- [ ] Represent every provider-supported setting in OpenTofu.
- [ ] Record any unavoidable console-only setting and its intended value.

Rollback: re-enable the prior Cloudflare exit-node setting. Do not introduce a
plain resolver as a temporary fallback.

### Phase 6: tighten Caddy and tailnet authorization

- [ ] Replace implicit wildcard fallthrough with explicit rejection.
- [ ] Apply source policy to `peerban`, `wpad`, `tv`, and `clash` as intended.
- [ ] Bind Caddy only to intended stable addresses.
- [ ] Replace the allow-all Tailscale ACL with separate service, management, and
      `autogroup:internet` grants.
- [ ] Treat public Tailscale-address DNS records as discovery only, never
      authorization.

Proof: valid clients reach only intended services; unmatched hosts and denied
sources receive an explicit failure rather than an empty 200.

### Phase 7: make sing-box configuration auditable

- [ ] Move non-secret inbounds, DNS rules, route rules, selectors, and logging
      policy into ordinary Nix.
- [ ] Limit SOPS data to private endpoints and credentials.
- [ ] Remove direct and Tailscale outbounds from groups named as proxy-only.
- [ ] Resolve the apparent US/China ruleset error against the live config.
- [ ] Guard optional generated rules so an empty matcher cannot become a broad
      catch-all.
- [ ] Use info-level timestamped logging by default; enable debug temporarily.
- [ ] Tailor systemd hardening with only the capabilities actually required.

Proof: the generated runtime JSON is reproducible except for secrets, passes
`sing-box check`, and its effective rule order matches the Nix policy.

### Phase 8: investigate Tailscale transport independently

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
| sing-box stopped | Local DNS remains available; no plaintext public fallback | Local/tailnet bypass; public fails closed | Local services work; public proxy traffic fails. |
| tailscaled stopped | LAN resolver remains available | Direct LAN only | Home LAN services work; remote tailnet access fails. |
| encrypted upstream unavailable | Local zone remains available | No DNS fallback to WAN port 53 | Public DNS fails closed. |
| IPv6 temporary address rotates | No resolver reload storm | Stable listeners unchanged | No user-visible interruption. |

Privacy proof should include a packet capture on `umi`'s WAN-facing interface:
representative client queries must not produce outbound TCP or UDP destination
port 53. Availability proof must exercise actual applications and arbitrary
ports, not only HTTPS and a successful DNS lookup.

## Emergency behavior

### Current configuration

If sing-box fails before Phase 2, the safest client-side recovery for LAN access
is to disable the exit node or Tailscale on the iPhone. Deleting the complete
TPROXY table would enable an untested ordinary exit-node path and could let DNS
addressed to `1.1.1.1:53` leave `umi` in plaintext. Do not use that as a privacy-
preserving fallback.

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

- `umi` LAN IPv4: `10.0.1.30`.
- `umi` Tailscale addresses: unknown. `tailscaled` runs logged out and
  `tailscale0` has no `100.x` address, so the exit-node/TPROXY path is inert
  until re-auth, at which point exit-node and DNS settings are re-decided.
- iPhone Tailscale addresses: `100.117.156.47` and
  `fd7a:115c:a1e0::4901:9c2f`.
- Tailscale advertises both IPv4 and IPv6 default routes from `umi`.
- `umi` uses `--accept-dns=false`; this affects only `umi`'s client resolver.
- MagicDNS is enabled with suffix `fin-orfe.ts.net`.
- The coordination server supplies Cloudflare global resolvers.
- sing-box version: 1.14.0.
- Tailscale version observed in the unit: 1.102.3.
- Policy table 169 contains IPv4 and IPv6 `local default dev lo` routes.
- The Nix reverse-path filter explicitly accepts the custom proxy mark.
- CoreDNS, dnscrypt-proxy, sing-box, tailscaled, and Caddy were running during
  the audit.
- `tailscaled.service` did not inherit the HTTP proxy environment.
- Caddy did inherit `networking.proxy.envVars`.
- The mixed and TPROXY listeners bind wildcard addresses.
- The host firewall globally permits their ports.

### Relevant history

- `b656f6fa`: introduced the TPROXY path.
- `45e06f1b`: added `--accept-dns=false`.
- `aa97b0d9`: disabled an attempted Tailscale split-DNS configuration.
- `442fb10f`: removed the commented split-DNS resource.

The history shows an incremental design rather than one coherent ownership
model: exit-node routing, resolver policy, and service discovery were adjusted
separately, leaving their combined failure behavior implicit.

### Important uncertainties

- Router DHCP/RA advertisements and inbound IPv6 firewall policy are not in the
  repository.
- The exact Tailscale **Use with exit node** value was inferred rather than read
  from the privileged netmap or console.
- The encrypted live sing-box configuration differs from the supplied decoded
  artifact; exact rule semantics must be checked against generated JSON.
- No controlled arbitrary-port test was completed from the iPhone during the
  audit.
- No fail-open standard exit-node path has been proven. IPv4 forwarding into
  `ts-forward` was zero, IPv6 saw only 12 packets, and neither Tailscale
  masquerade rule saw a packet; this path must not be treated as a ready
  fallback.
- The cause of the Tailscale map-poll/DERP instability remains unresolved.
- Public IPv6 reachability through the router was not tested, although host-side
  exposure is confirmed.

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
- Do not replace CoreDNS/dnscrypt solely to reduce the number of daemons.

Decisions still required during implementation:

- Whether unsupported public protocols are dropped or sent directly. Default:
  drop.
- Whether public DNS policy remains in sing-box or moves entirely to the stable
  resolver after encrypted-upstream testing.
- Whether CoreDNS plus dnscrypt-proxy remains the final resolver pair or Unbound
  provides a meaningful simplification.
- Which services, if any, should be reachable through public GUAs.
- Which Tailscale identities may use the exit node and administrative services.
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
- `nixos/services/avahi2dns/module.nix`
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
- [CoreDNS `bind`](https://coredns.io/plugins/bind/)
