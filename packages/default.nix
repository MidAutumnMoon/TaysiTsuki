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

in rec {

    tsuki = discovered // {
        # test builds
        localbinbox = callPackage ../home/localbinbox {};
        portableTest = callPackage ./portable/test.nix {};

        # Using lib.fileset to avoid unnecessary non-rust rebuilds.
        workspace =
            let
                inherit (lib.fileset)
                    unions toSource intersection gitTracked;
                inherit (lib.path) append;
                inherit (lib.strings) hasInfix;
                root = ../.;
                workspaceRootToml = append root "Cargo.toml";
                workspaceLock = append root "Cargo.lock";
                membersSrc =
                    lib.importTOML workspaceRootToml
                    |> (m: m.workspace.members)
                    # assert that "members" does not contains glob
                    |> (ms:
                        assert lib.all (m: !hasInfix m "*") ms;
                        ms)
                    |> map (append root);
                workspaceSrc = unions <|
                    [ workspaceRootToml workspaceLock ]
                    ++ membersSrc;
            in {
                cargoLock.lockFile = workspaceLock;
                src = toSource {
                    inherit root;
                    fileset = intersection
                        (gitTracked root) workspaceSrc;
                };
            };
    };

    inherit (pkgsFrom "sops-nix")
        sops-install-secrets
    ;

    # tangled = {
    #     inherit (pkgsFrom "tangled")
    #         knot
    #     ;
    # };

    dnscrypt-proxy = tsuki.dnscrypt;

    feishin = lib.useElectronBin prev prev.feishin;
    obsidian = lib.useElectronBin prev prev.obsidian;

    yt-dlp = prev.yt-dlp.override {
        inherit (tsuki) deno;
    };

    zram-generator =
        lib.onceride prev.zram-generator
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    sudo-rs =
        lib.onceride prev.sudo-rs
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    #
    # Lix overrides
    #

    lixSet = prev.lixPackageSets.latest;

    inherit (lixSet)
        lix
        # The default "lix" points to old stable version
        nix-eval-jobs
    ;

    nixVersions = prev.nixVersions // {
        stable = lixSet.lix;
        latest = lixSet.lix;
    };

    nixForLinking = prev.nixVersions.stable;

    # TODO: get rid of colmena flake
    colmena =
        (pkgsFrom "colmena").colmena.override {
            nix-eval-jobs = final.nix-eval-jobs;
            rustPlatform = final.tsuki.rust;
        };

    nix-direnv =
        prev.nix-direnv.override { nix = final.lix; };

}
