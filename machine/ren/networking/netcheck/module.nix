{ lib, config, pkgs, ... }:

let

    inherit (config.lore)
        apps
        machines
        domains
    ;

    umi = machines.umi;
    umiFqdn = "${umi.hostname}.${domains.im_418}";

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

            check() {
                local name=$1 detail=$2
                shift 2
                if "$@" >/dev/null 2>&1; then
                    echo "PASS: $name ($detail)"
                else
                    echo "FAIL: $name ($detail)"
                    fail=1
                fi
            }

            # resolvectl puts extra servers on unlabeled continuation
            # lines, so scan the whole Global block for address-like
            # tokens instead of trusting labeled lines
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

            # Self.AllowedIPs is this node's routes in the netmap;
            # this tailscale version has no AdvertisedRoutes field
            ts=$(tailscale status --json || true)
            state=$(jq -r '.BackendState // empty' <<<"$ts" || true)
            check "tailscale backend is running" "state: $state" \
                [ "$state" = "Running" ]
            check "exit node route advertised" \
                "Self.AllowedIPs: $(jq -r '.Self.AllowedIPs // [] | join(", ")' <<<"$ts")" \
                jq -e '(.Self.AllowedIPs // []) | index("0.0.0.0/0")' <<<"$ts"

            # quad-100 carries magicdns + split domains (needs
            # accept-dns=true); the ~. default route is tailnet-wide
            # capture into umi's sing-box (infra/tailscale.tf)
            tsdns=$(resolvectl dns tailscale0 2>/dev/null || true)
            check "tailscale0 link carries quad-100" "got: ''${tsdns:-none}" \
                grep -q "100.100.100.100" <<<"$tsdns"
            tsdom=$(resolvectl domain tailscale0 2>/dev/null || true)
            check "tailscale0 link routes ~. (dns capture live)" "got: ''${tsdom:-none}" \
                grep -qE '(^|[[:space:]])~\.' <<<"$tsdom"

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
