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

        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs";
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

        nyx = {
            url = "github:chaotic-cx/nyx";
            inputs.nixpkgs.follows = "nixpkgs";
            inputs.home-manager.follows = "empty";
            inputs.jovian = {
                inputs.nixpkgs.follows = "nixpkgs";
                inputs.nix-github-actions.follows = "empty";
            };
            inputs.flake-schemas.follows = "empty";
            inputs.rust-overlay.follows = "rust-overlay";
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

        inherit lib flakes;

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
                    self.nixosModules.only-nyx-cache 
                ]
                ++ ( lib.listAllModules ./nixos )
                ++ ( lib.listAllModules ./secrets );
            nixos = lib.brewOS {
                inherit pkgsBrew modules;
                arguments = { inherit flakes; };
            };
        in {
            ren = nixos "x86_64-linux" <| lib.listAllModules ./machine/ren;
            phia = nixos "x86_64-linux" <| lib.listAllModules ./machine/phia;
            uk-01 = nixos "x86_64-linux" <| (
                lib.listAllModules ./machine/uk-01
                ++ [ flakes.disko.nixosModules.default ]
            );
        };

        # Remove nix-community cache and future ones.
        nixosModules.only-nyx-cache = { lib, ... }:
            let
                isChaotic = lib.strings.hasInfix "chaotic-nyx";
                substrs = flakes.nyx.nixConfig.extra-substituters;
                keys = flakes.nyx.nixConfig.extra-trusted-public-keys;
            in {
                nix.settings = {
                    substituters =
                        lib.mkAfter <| lib.filter isChaotic substrs;
                    trusted-public-keys =
                        lib.mkAfter <| lib.filter isChaotic keys;
                };
            };

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
                uk-01.deployment = {
                    targetHost = "uk-01";
                    targetUser = "root";
                };
            }
            |> lib.nixos2colmena self.nixosConfigurations
            |> flakes.colmena.lib.makeHive;
    };

}
