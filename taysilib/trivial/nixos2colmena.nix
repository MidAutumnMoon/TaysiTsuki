lib:

let

    inherit ( lib )
        mapAttrs
        recursiveUpdate
    ;

in {

    nixos2colmena = configs: overrides: let
        meta = {
            nodeNixpkgs = mapAttrs ( _: cfg: cfg.pkgs ) configs;
            nodeSpecialArgs = mapAttrs ( _: cfg: cfg._module.specialArgs ) configs;
        } // overrides.meta or {};
        body =
            # Stupid long hand colmena tries to apply "smart" nixpkgs.config,
            # however it conflicts with my workflow.
            let nocfg = [ { nixpkgs.config = lib.mkForce {}; } ]; in
            let modulesOf = cfg: { imports = cfg._module.args.modules ++ nocfg; }; in
            mapAttrs ( _: cfg: modulesOf cfg ) configs
            |> recursiveUpdate ( removeAttrs overrides [ "meta" ] )
        ;
    in { inherit meta; } // body;

}
