lib:

let

    inherit ( lib )
        isAttrs
        isList
        isDerivation
        mapAttrs
    ;

    brewer = pkgs: recipe:
        let drink = pkgs |> recipe; in
        let mkShellImpl = pkgs.mkShellNoCC; in
        if isList drink then
            mkShellImpl { packages = drink; }
        else if isAttrs drink && !isDerivation drink then
            mkShellImpl drink
        else
            drink
    ;

in {

    # brewShells :: pkgsBrew -> attrset of recipes -> attrset
    # where
    #   pkgsBrew: somthing cooked using ./brewNixpkgs.nix
    #   recipe: pkgs -> list | attrset | anything
    brewShells = pkgsBrew: shellRecipes:
        assert isAttrs shellRecipes;
        pkgsBrew ( pkgs: mapAttrs ( _: r: brewer pkgs r ) shellRecipes )
    ;

}
