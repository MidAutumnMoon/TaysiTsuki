{

    inputs = {

        nixpkgs.url =
            "github:NixOS/nixpkgs/nixos-unstable-small";

        # Some packages

        colmena = {
            url = "github:zhaofengli/colmena";
            inputs.nixpkgs.follows = "nixpkgs";
            inputs.stable.follows = "nixpkgs";
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

        # Some modules

        preservation.url = "github:nix-community/preservation";

        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nixos-wsl = {
            url = "github:nix-community/NixOS-WSL";
            inputs.nixpkgs.follows = "nixpkgs";
        };

    };

    outputs = { self, nixpkgs, ... } @ flakes: let

        lib = nixpkgs.lib.extend ( import ./lib );

        pkgsBrew = lib.brewNixpkgs nixpkgs {
            config = { allowUnfree = true; };
            overlays = builtins.attrValues self.overlays;
        };

    in {

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
                    self.nixosModules.homeManagerAdapter
                    sops-nix.nixosModules.default
                    preservation.nixosModules.default
                    home-manager.nixosModules.home-manager
                ]
                ++ ( lib.listAllModules ./nixos );
            nixos = lib.brewNixOS {
                inherit pkgsBrew modules;
                arguments = { inherit flakes; };
            };
        in {
            loonie = nixos "x86_64-linux" [
                ./machine/loonie
                flakes.nixos-wsl.nixosModules.default
            ];

            ren = nixos "x86_64-linux" [ ./machine/ren ];
            phia = nixos "x86_64-linux" [ ./machine/phia ];
        };

        colmenaHive = lib.nixos2colmena self.nixosConfigurations
            {
                meta.nixpkgs = pkgsBrew.pkgsOf "x86_64-linux";
                ren.deployment.targetHost = "ren.home.lan";
                phia.deployment = {
                    targetHost = "phia.home.lan";
                    targetUser = "root";
                };
            }
            |> flakes.colmena.lib.makeHive
        ;

        nixosModules.homeManagerAdapter =
            { lib, ... }: let
                hmLibWithNulib =
                    "${flakes.home-manager}/modules/lib/stdlib-extended.nix"
                    |> ( f: import f lib )
                ;
            in { home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                    inherit flakes;
                    lib = hmLibWithNulib;
                };
                sharedModules =
                    lib.listAllModules ./home
                    ++ [ flakes.sops-nix.homeManagerModules.sops ]
                    ++ [ { home.stateVersion = lib.trivial.release; } ]
                    ++ [ { programs.man.generateCaches = false; } ]
                ;
            }; }
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

