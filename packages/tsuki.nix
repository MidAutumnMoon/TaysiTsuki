# Package maintenance manifest, consumed by `tsuki.__ci`:
#
#     nix run .#tsuki.__ci -- build  -m packages/tsuki.nix -l
#     nix run .#tsuki.__ci -- build  -m packages/tsuki.nix -g <group>
#     nix run .#tsuki.__ci -- update -m packages/tsuki.nix
#
# Each attribute is a build group; CI builds its members as one job and
# caches them. Packages under the tsuki namespace use the `tsuki`
# constructor and are tracked upstream by nix-update. Everything else
# uses `pkgs` — never tracked, built only to be cached; the version
# moves with `flake.lock`.

let

    inherit (builtins)
        attrValues
        concatMap
        elem
        foldl'
        isAttrs
        isString
        length
        mapAttrs
        ;

    # A package under the tsuki namespace. Tracked upstream by
    # default; pass an attrset to configure how the next version is
    # determined, or `null` to build it without tracking:
    #
    #     tsuki "caddy"
    #     tsuki "hysteria" { version.regex = "app/v(.*)"; }
    #     tsuki "psd-rs" null
    #
    tsuki = name: {
        attrpath = "tsuki.${name}";
        track = { };
        __functor = self: track:
            if track == null then
                self // { inherit track; }
            else if isAttrs track then
                self // { track = checkTrack track; }
            else
                throw "tsuki \"${name}\": track must be an attrset or null";
    };

    # How nix-update finds the next version. The only knob is
    # `version`; anything else is a typo:
    #
    #     "branch"           latest commit of the default branch
    #     "unstable"         pre-release versions
    #     version.regex = ... extract the version with a custom regex
    checkTrack = { version ? null }: { inherit version; };

    # A package from nixpkgs or another flake input. Never tracked;
    # the version moves with `flake.lock`.
    pkgs = attrpath:
        if isString attrpath then
            { inherit attrpath; track = null; }
        else
            throw "pkgs: attrpath must be a string";

    # Reduce an entry to the JSON shape `__ci` parses.
    toWire = entry: { inherit (entry) attrpath track; };

    checkGroup = name: members:
        if members == [ ] then
            throw "Group \"${name}\" is empty"
        else
            map toWire members;

    allUnique = groups:
        let
            paths =
                concatMap
                    (members: map (entry: entry.attrpath) members)
                    (attrValues groups);
            uniq = foldl'
                (acc: path: if elem path acc then acc else acc ++ [ path ])
                [ ]
                paths;
        in
            length paths == length uniq;

    finalize = groups:
        if allUnique groups then
            mapAttrs checkGroup groups
        else
            throw "Duplicated attrpaths found";

in

finalize {

    #
    # small 1
    #
    Small_Trivial_1 = [
        (tsuki "adblocklist")
        (tsuki "metacubexd")
        (tsuki "monaspace")
        (tsuki "peerbanhelper")
        (tsuki "rust.rust-analyzer")
        (tsuki "zed")
        (tsuki "deno")
        (tsuki "sing-box")
        (tsuki "sillytavern-token-estimate" { version = "branch"; })
        (tsuki "playwright-cli.unwrapped" {
            # microsoft/playwright-cli also publishes deprecated stub tags (e.g. v0.180.0)
            # whose empty lockfile breaks prefetch-npm-deps and sorts above the real 0.1.x
            # CLI; pin discovery to the 0.1.x series.
            version.regex = "v(0\\.1\\..*)";
        })
    ];

    #
    # go 1
    #
    Go_1 = [
        (tsuki "caddy")
        (tsuki "dnscrypt")
        (pkgs "sops-install-secrets")
        (tsuki "hysteria" { version.regex = "app/v(.*)"; })
        (tsuki "avahi2dns")
    ];

    #
    # go 2
    #
    Go_2 = [
        (tsuki "coredns" { version.regex = "(v1\\..*)"; })
        # nixpkgs opentofu wrapped with plugins; version moves with
        # flake.lock, so there is nothing upstream to track.
        (tsuki "opentofu" null)
        # (tsuki "octopus")
    ];

    #
    # rust 1
    #
    Rust_1 = [
        (tsuki "shadowsocks")
        # First-party crates built from the workspace; no upstream to
        # track.
        (tsuki "psd-rs" null)
        (tsuki "mimic-cloud-init" null)
        (pkgs "zram-generator")
        (pkgs "sudo-rs")
    ];

    #
    # rust 2
    #
    Rust_2 = [
        (tsuki "nushell")
    ];

    Inori = [
        (tsuki "inori" { version = "branch"; })
    ];

    #
    # Others, built only to make sure being cached
    #
    Lix = [ (pkgs "lix") ];
    Colmena = [ (pkgs "colmena") ];
    # nixpkgs niri with local patches; version moves with flake.lock.
    Niri = [ (tsuki "niri" null) ];
}
