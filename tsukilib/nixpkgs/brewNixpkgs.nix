lib:

let

    inherit ( lib )
        mapAttrs
        makeExtensible
        isList
        isString
        filterAttrs
        elem
    ;

    inherit ( lib.tsuki.trivial )
        eachSystem
    ;

    __brewNixpkgs = nixpkgs: options: makeExtensible ( self: {
        # __pkgs :: { "x86_64-linux" = pkgs; ... }
        #
        # Attr of system triples to the initialized nixpkgs instances;
        __pkgs = self.__eachSystem ( system:
            import nixpkgs ( { inherit system; } // self.__options )
        );

        # __eachSystem :: "eachSystem" object
        #
        # Capture the eachSystem so that it can be updated later if needed.
        __eachSystem = eachSystem;

        # __options :: import <nixpkgs> {...}
        #                               ^ shape of this thing
        #
        # Captured "options" because it can be updated later.
        __options = options;

        # __functor :: self -> ( pkgs -> 'a ) -> { "x86_64-linux" = 'a; ... }
        #
        # The magic functor. See `brewNixpkgs` for a explaination
        # of such design.
        __functor = self: fn:
            mapAttrs ( _system: pkgs: fn pkgs ) self.__pkgs;

        # __updateOptions :: string -> 'a -> ( 'a -> 'b ) -> self
        #
        # Handy function for updating one field in `__options`.
        __updateOptions = name: fallback: updater:
            self.extend ( _: prev: let
                __o = prev.__options;
            in {
                __options = __o // {
                    ${name} = updater ( __o.${name} or fallback );
                };
            } );

        # pkgsOf :: string -> pkgs
        #
        # Get the instance of pkgs of the given system.
        pkgsOf = system:
            assert isString system;
            self.__pkgs.${system};

        pkgsOfSystems = systems:
            assert lib.all isString systems;
            filterAttrs ( s: _: elem s systems ) self.__pkgs;

        # appendOverlays :: [ overlay ] -> self
        #
        # Append more overlays to nixpkgs option.
        appendOverlays = xs:
            assert isList xs;
            self.__updateOptions "overlays" [] ( old: old ++ xs );

        # appendSystems :: [ "system triple" ] -> self
        #
        # Add more systems to the output.
        appendSystems = xs:
            assert lib.all isString xs;
            self.extend ( _: prev: {
                __eachSystem = prev.__eachSystem.appendSystems xs;
            } );
    } ) ;

in

{

    # brewNixpkgs :: nixpkgs -> nixpkgs option -> { `system` = pkgs }
    #   where `system` comes form [ "x86_64-linux" "aarch-darwin" ... ]
    #
    # Automatically import nixpkgs for commonly supported systems.
    #
    # Usage
    #
    #   Feed this function with `nixpkgs` and `nixpkgs options`, like:
    #   pkgsBrew = brewNixpkgs inputs.nixpkgs { allowUnfree = false; };
    #
    #   It gives back an attrset of systems mapped to imported nixpkgs, like:
    #   { # pkgsBrew
    #       "x86_64-linux" = <<pkgs of x86_64-linux>>;
    #       etc.;
    #       __functor;
    #   }
    #
    #   This process is called "brew", thus the function name :)
    #
    #   The `__functor` is a convenient function for iterating on all pkgs:
    #   packages = pkgsBrew ( p: { inherit (p) cowsay; } )
    #   -> { #packages
    #       "x86_64-linux" = { cowsay = <<drv>>; };
    #       etc.;
    #   }
    #
    #   The `__functor` will remove itself from the result.
    #
    #   This lines up quite nicely with the flake semantics.
    #
    # Tips
    #
    #   1) `system` can be accessed within each `pkgs`, e.g.
    #   pkgsBrew ( p: p.system ) -> { `system` = system string; }
    #
    brewNixpkgs = __brewNixpkgs;

}
