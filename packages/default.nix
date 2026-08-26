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

    inherit (pkgsFrom "llm-agents")
        omp
    ;

    linuxCachyos =
        (legacyFrom "nix-cachyos-kernel")
        .linuxPackages-cachyos-latest-lto-x86_64-v3;

    # tangled = {
    #     inherit (pkgsFrom "tangled")
    #         knot
    #     ;
    # };

    dnscrypt-proxy = tsuki.dnscrypt;

    obsidian = lib.useElectronBin prev prev.obsidian;

    navidrome = prev.navidrome.overrideDerivation (old: {
        CGO_CFLAGS_ALLOW = "--define-prefix";
    });

    yt-dlp = prev.yt-dlp.override {
        inherit (tsuki) deno;
    };

    # 154 has bugs, keep 153.0.4 from the pinned nixpkgs.
    firefox = (legacyFrom "nixpkgs-firefox").firefox;

    zram-generator =
        lib.onceride prev.zram-generator
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    sudo-rs =
        lib.onceride prev.sudo-rs
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    # qtwebengine is only used for the stupid sougo online dict
    kdePackages = prev.kdePackages.overrideScope (_self: kdeSuper: {
        fcitx5-chinese-addons =
            lib.onceride kdeSuper.fcitx5-chinese-addons
            { qtwebengine = null; }
            (old: {
                cmakeFlags = (old.cmakeFlags or []) ++ [ "-DENABLE_BROWSER=Off" ];
            });
    });

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
