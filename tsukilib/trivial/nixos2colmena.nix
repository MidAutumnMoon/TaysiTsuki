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
            let modulesOf = cfg: { imports = cfg._module.args.modules; }; in
            mapAttrs ( _: cfg: modulesOf cfg ) configs
            |> recursiveUpdate ( removeAttrs overrides [ "meta" ] )
        ;
    in { inherit meta; } // body;

}
