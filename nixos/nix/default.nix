{ lib, pkgs, flakes, ... }:

{

    nix.package = pkgs.nixVersions.stable;

    nix.settings = {
        auto-optimise-store = true;
        keep-going = true;
        narinfo-cache-negative-ttl = 60;

        # Let cache.nixos.org be queried first.
        substituters = lib.mkAfter [
            "https://nuirrce.cachix.org"
        ];
        trusted-public-keys = [
            "nuirrce.cachix.org-1:KQWa6ZfDkMPXeDiUpmyDhNw4CmgybPyeVklmi/1Rtqk="
        ];

        auto-allocate-uids = true;
        use-cgroups = true;
        experimental-features = [
            "nix-command"
            "flakes"
            "ca-derivations"
            "auto-allocate-uids"
            "cgroups"
            "pipe-operators"
        ];
        use-xdg-base-directories = true;
        always-allow-substitutes = true;
    };

    nix.registry = {
        "short" = {
            from = { id = "p"; type = "indirect"; };
            to = { type = "path"; path = flakes.nixpkgs; };
        };
    };

    nix.nixPath = [
        "nixpkgs=${toString flakes.nixpkgs}"
        "nixos=${toString flakes.nixpkgs}"
    ];

    nix.channel.enable = false;

    nix.gc = {
        automatic = true;
        options = "--delete-older-than 7d";
    };

}
