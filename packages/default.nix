{ lib, flakes }:

final: prev:

let

    callPackage = final.newScope {
        inherit lib flakes;
    };

    hostSystem = final.stdenv.hostPlatform.system;

    pkgsFrom =
        name: flakes.${name}.packages.${hostSystem};

    legacyFrom =
        name: flakes.${name}.legacyPackages.${hostSystem};

    discovered =
        lib.packagesFromDirectoryRecursive {
            inherit callPackage;
            directory = ./.;
        };

    # First-party crates of the Rust workspace; see ../rust.
    rustApps = import ../rust { inherit lib callPackage; };

in rec {

    tsuki = discovered // rustApps // {

        # test builds
        portableTest = callPackage ./portable/test.nix {};

        kde = callPackage ./kde/package.nix {
            kdePackages = prev.kdePackages;
        };

        fish = callPackage ./fish/package.nix {
            fish = prev.fish;
        };
    };

    inherit (pkgsFrom "sops-nix")
        sops-install-secrets
    ;

    linuxCachyos = tsuki.cachyos.linuxPackages;

    # tangled = {
    #     inherit (pkgsFrom "tangled")
    #         knot
    #     ;
    # };

    dnscrypt-proxy = tsuki.dnscrypt;

    obsidian = lib.useElectronBin prev prev.obsidian;

    fish = tsuki.fish;

    helix = tsuki.helix;

    yt-dlp = prev.yt-dlp.override {
        jsRuntime = prev.nodejs;
    };

    # `nix flake metadata` in nix 2.35 no longer materializes the store path
    # that `nix-update --flake` passes to `nix-instantiate` (Mic92/nix-update#687).
    nix-update = prev.nix-update.override {
        nix = prev.nixVersions.nix_2_34;
    };

    zram-generator =
        lib.onceride prev.zram-generator
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    sudo-rs =
        lib.onceride prev.sudo-rs
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    kdePackages = tsuki.kde;

}
