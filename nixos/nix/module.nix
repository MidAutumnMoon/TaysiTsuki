{ lib, pkgs, flakes, ... }:

{

    nix.package = pkgs.lix;

    nix.settings = {
        auto-optimise-store = false;
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
            "auto-allocate-uids"
            "cgroups"
            "pipe-operator"
            "lix-custom-sub-commands"
        ];
        use-xdg-base-directories = true;
        always-allow-substitutes = false;

        temp-dir = "/tmp";
        # insecure, but well enough
        build-dir = "/tmp";
    };

    nix.registry = {
        "short" = {
            from = { id = "p"; type = "indirect"; };
            to = { type = "path"; path = flakes.self; };
        };
    };

    nix.channel.enable = false;

    nix.gc = {
        automatic = true;
        options = "--delete-older-than 3d";
    };

    nix.optimise = {
        automatic = true;
    };

    nix.daemonCPUSchedPolicy = "batch";

}
