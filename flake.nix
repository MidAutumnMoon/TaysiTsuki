{

    inputs = {

        nixpkgs.url =
            "github:NixOS/nixpkgs/nixos-unstable-small";

        # Some modules

        preservation.url = "github:nix-community/preservation";

        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        dns = {
            url = "github:nix-community/dns.nix";
            inputs.nixpkgs.follows = "nixpkgs";
            inputs.flake-utils.follows = "flake-utils";
        };

        # Some packages

        colmena = {
            url = "github:zhaofengli/colmena";
            inputs.nixpkgs.follows = "nixpkgs";
            inputs.flake-utils.follows = "flake-utils";
            inputs.flake-compat.follows = "empty";
            inputs.stable.follows = "empty";
            inputs.nix-github-actions.follows = "empty";
        };

        nix-index-database = {
            url = "github:nix-community/nix-index-database";
            flake = false;
        };

        # Some toolchains

        rust-overlay = {
            url = "github:oxalica/rust-overlay";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # Follows

        empty.url = "github:MidAutumnMoon/empty-flake";

        flake-utils = {
            url = "github:numtide/flake-utils";
        };

    };

    outputs = { self, nixpkgs, ... } @ flakes: let

        lib = nixpkgs.lib.extend ( import ./tsukilib );

        pkgsBrew = lib.brewNixpkgs nixpkgs {
            config = { allowUnfree = true; };
            overlays = [
                self.overlays.nuclage
            ];
        };

    in rec {

        /*
         * My cute lib
         */

        inherit lib;

        /*
         * Overlays & packages
         */

        overlays.nuclage =
            import ./packages { inherit lib flakes; };

        inherit pkgsBrew;

        packages = self.pkgsBrew lib.id;

        /*
         * Machines
         */

        nixosConfigurations = let
            modules =
                with flakes; [
                    sops-nix.nixosModules.default
                    preservation.nixosModules.default
                    ./lore/module.nix
                ]
                ++ ( lib.listAllModules ./nixos )
                ++ ( lib.listAllModules ./secrets );
            nixos = lib.brewOS {
                inherit pkgsBrew modules;
                arguments = { inherit flakes; };
            };
        in {
            ren = nixos "x86_64-linux" <| lib.listAllModules ./machine/ren;
            phia = nixos "x86_64-linux" [ ./machine/phia ];
        };

        x = lib.listAllModules ./machine/ren;

        colmenaHive =
            {
                meta.nixpkgs = pkgsBrew.pkgsOf "x86_64-linux";
                ren.deployment = {
                    targetHost = "ren.local";
                    buildOnTarget = true;
                };
                phia.deployment = {
                    targetHost = "phia.local";
                    targetUser = "root";
                };
            }
            |> lib.nixos2colmena self.nixosConfigurations
            |> flakes.colmena.lib.makeHive
        ;

        /*
         * devShells
         */

        devShells = lib.brewShells pkgsBrew {

            rust = p: with p; [
                rustc
                cargo
                cargo-bloat
                cargo-nextest
                cargo-outdated
                cargo-edit
                clippy
                rustfmt
                rust-analyzer
                stdenvTeapot.cc
                pkg-config
            ];

            music = p: with p; [
                picard
                shntool cuetools flac
            ];

        };
    };

}

