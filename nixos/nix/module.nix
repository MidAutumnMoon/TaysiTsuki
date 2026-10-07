{ lib, flakes, pkgs, ... }:

let

    buildDir = "/nix/var/nix/builds";
    fsTypeOfBuildDir = "xfs";

in

{
    nix.package = pkgs.nixVersions.latest;

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
            "auto-allocate-uids"
            "cgroups"
            "pipe-operators"
        ];
        use-xdg-base-directories = true;
        always-allow-substitutes = false;

        # insecure, but well enough
        build-dir = buildDir;
    };

    # N.B. The hardcoded "2" is fragile. It assumes the host has zram0 and zram1,
    # which are swap and /tmp in my setup. If a new module from nixpkgs also uses
    # zram in the future, it might break eval because zram2 is defined twice.
    # But that's better than break running system.
    #
    # Alternatively it can use a "hack" as in "boot/zram-as-tmp.nix". But hardcode 2
    # is good enough for now.
    #
    # Some constraints:
    # - zram must end in numeric sequence, zram0, zram1, zram2...
    # - zram-generator creates new zram device up until the hightes device number,
    #   without caring whether it's actually used. For example, with there active
    #   device zram0, zram1, zram6969, zram-generator will create ~7k zram devices,
    #   and only 3 of which are used, others are wasted.
    #
    # I hate this, as well as zram-generator. But, meh, it works for now.
    services.zram-generator.settings."zram2" = {
        compression-algorithm = "zstd";
        fs-type = fsTypeOfBuildDir;
        mount-point = buildDir;
        # nix errors if build dir is everyone writable (i.e. /tmp)
        options = "X-mount.mode=0755,discard";
        zram-size = "ram";
    };

    systemd.services.nix-daemon = {
        unitConfig.RequiresMountsFor = [ buildDir ];
    };

    boot.supportedFilesystems = {
        ${fsTypeOfBuildDir} = true;
    };

    nix.registry.p.flake = flakes.self;

    # A registry path only retains the top-level flake source, not its inputs.
    # Keep nixpkgs in the system closure so GC cannot evict it between uses.
    system.extraDependencies = [
        flakes.nixpkgs.outPath
    ];

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
