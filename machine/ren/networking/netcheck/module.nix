{ lib, config, pkgs, ... }:

# `netcheck`: runtime verification of the network stack.
# Expected fqdn->address pairs are generated from lore at build time.

let

    inherit (config.lore)
        apps
        machines
        domains
    ;

    umi = machines.umi;
    umiFqdn = "${umi.hostname}.${domains.im_418}";

    # fqdn + expected IPv4 pairs
    expected =
        let
            appAddr = app:
                if app.cname == umiFqdn then umi.static_ip else app.ip;
        in
            [ "${umiFqdn} ${umi.static_ip}" ]
            ++ (
                ( with apps; homelab // tailnet )
                |> lib.attrValues
                |> lib.map (app: "${app.fqdn} ${appAddr app}")
            );

    netcheck = pkgs.writeShellApplication {
        name = "netcheck";
        runtimeInputs = with pkgs; [
            gawk
            jq
            systemd
            tailscale
        ];
        text = ''
            fail=0

            check() { # name detail command...
                local name=$1 detail=$2
                shift 2
                if "$@" >/dev/null 2>&1; then
                    echo "PASS: $name ($detail)"
                else
                    echo "FAIL: $name ($detail)"
                    fail=1
                fi
            }

            # 1. resolved: the stub points at dnscrypt only, no fallback
            # leak. Extra servers can sit on unlabeled continuation
            # lines, so scan the whole Global block for address-like
            # tokens instead of trusting labeled lines.
            global=$(
                { resolvectl status || true; } \
                    | awk '/^Global/ {g = 1; next} /^Link/ {g = 0} g'
            )
            v4=$(
                { grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' <<<"$global" || true; } \
                    | sort -u | xargs
            )
            v6=$(
                { grep -oE '([0-9a-fA-F]{0,4}:){2,}[0-9A-Za-z:.]*' <<<"$global" || true; } \
                    | sort -u | xargs
            )
            check "resolved global DNS is 127.0.0.1 only" "got: ''${v4:-none}" \
                [ "$v4" = "127.0.0.1" ]
            check "resolved global has no other address" "got: ''${v6:-none}" \
                [ -z "$v6" ]

            # 2. lore fqdns resolve to their expected address
            # (failures must be reported, not abort the loop:
            # errexit + pipefail are in effect)
            while read -r fqdn ip; do
                [ -n "$fqdn" ] || continue
                got=$(
                    { getent ahostsv4 "$fqdn" || true; } \
                        | awk 'NR == 1 { print $1 }'
                )
                check "$fqdn resolves" "expected $ip, got ''${got:-none}" \
                    [ "$got" = "$ip" ]
            done <<EOF
            ${lib.join "\n" expected}
            EOF

            # 3. tailscale: running and advertising the exit node route.
            # Self.AllowedIPs is the netmap view of this node's routes;
            # this tailscale version has no AdvertisedRoutes field.
            ts=$(tailscale status --json || true)
            state=$(jq -r '.BackendState // empty' <<<"$ts" || true)
            check "tailscale backend is running" "state: $state" \
                [ "$state" = "Running" ]
            check "exit node route advertised" \
                "Self.AllowedIPs: $(jq -r '.Self.AllowedIPs // [] | join(", ")' <<<"$ts")" \
                jq -e '(.Self.AllowedIPs // []) | index("0.0.0.0/0")' <<<"$ts"

            # 3b. magicdns + dns capture: quad-100 (magic + split
            # domains; accept-dns must stay true for it) and the ~.
            # default route (tailnet-wide capture via the sing-box
            # listener, infra/tailscale.tf) are both on tailscale0.
            tsdns=$(resolvectl dns tailscale0 2>/dev/null || true)
            check "tailscale0 link carries quad-100" "got: ''${tsdns:-none}" \
                grep -q "100.100.100.100" <<<"$tsdns"
            tsdom=$(resolvectl domain tailscale0 2>/dev/null || true)
            check "tailscale0 link routes ~. (dns capture live)" "got: ''${tsdom:-none}" \
                grep -qE '(^|[[:space:]])~\.' <<<"$tsdom"

            # 4. bogus .local names must not resolve
            if getent ahostsv4 something-invalid.local >/dev/null 2>&1; then
                echo "FAIL: invalid .local name fails (getent returned an address)"
                fail=1
            else
                echo "PASS: invalid .local name fails (no address returned)"
            fi

            exit "$fail"
        '';
    };

in {

    environment.systemPackages = [ netcheck ];

}
