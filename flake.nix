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

        # tangled = {
        #     url = "git+https://tangled.org/tangled.org/core?shallow=1";
        #     inputs = {
        #         nixpkgs.follows = "nixpkgs";
        #         flake-compat.follows = "empty";
        #         gomod2nix.inputs.flake-utils.follows = "flake-utils";
        #         indigo.follows = "empty";
        #         htmx-src.follows = "empty";
        #         htmx-ws-src.follows = "empty";
        #         lucide-src.follows = "empty";
        #         inter-fonts-src.follows = "empty";
        #         actor-typeahead-src.follows = "empty";
        #         ibm-plex-mono-src.follows = "empty";
        #     };
        # };

        noctalia = {
            url = "github:noctalia-dev/noctalia-shell";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # N.B. do NOT override nixpkgs input, for caching
        nix-cachyos-kernel = {
            url = "github:xddxdd/nix-cachyos-kernel";
            inputs.flake-compat.follows = "empty";
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
                ]
                ++ (lib.listAllModules ./nixos)
                ++ (lib.listAllModules ./sops);
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
            sjc-01 = nixos "x86_64-linux" <| (
                lib.listAllModules ./machine/sjc-01
                ++ [ flakes.disko.nixosModules.default ]
            );
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
            |> lib.flip removeAttrs [ "ren" ]
            |> flakes.colmena.lib.makeHive;
    };

}
