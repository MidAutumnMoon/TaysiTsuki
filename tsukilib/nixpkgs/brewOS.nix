lib:

let

    inherit ( lib )
        isAttrs
        isList
        isString
        singleton
    ;

in

{

    # brewOS :: forget about the type
    brewOS =
        # pkgsBrew :: the object generated using brewNixpkgs.nix
        # modules :: shared modules
        # arguments :: shared _module.args
        { pkgsBrew, modules ? [], arguments ? {} }:
        # system :: the system string like "x86_64-linux"
        system:
        # machineModules :: modules specific to one machine
        machineModules:
            assert isList modules;
            assert isAttrs arguments;
            assert isString system;
            assert isList machineModules;
            let
                cfgMod = {
                    nixpkgs = pkgsBrew.__options // { inherit system; };
                    _module.args = arguments;
                };
            in
            lib.nixosSystem {
                specialArgs = { inherit lib; };
                modules =
                    ( singleton cfgMod )
                    ++ modules
                    ++ machineModules;
            };

}
