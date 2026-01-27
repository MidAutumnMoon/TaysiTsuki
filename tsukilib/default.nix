self: _super:

let

    # activate :: path -> attrset
    #
    # `toplevel` is a dir containing a `default.nix`.
    #
    # That `default.nix` contains a list of paths to more .nix files
    # containing a function of sig `lib -> attrset`, where `lib` is
    # the `nixpkgs.lib` itself (aka. the `self` parameter at the top
    # of this file).
    #
    # Each of such function is applied with `lib`, the result list of attrsets
    # will be flattened into one. Thus beware of naming conflicts.
    activate = toplevel:
        toplevel
        # Import the `default.nix` to get the list of paths
        |> import
        # Import each path to get the lib functions
        |> map import
        # Apply `lib` to lib functions
        |> map ( m: m self )
        # Merge all result attrsets
        |> builtins.foldl' ( a: b: a // b ) {}
    ;

in

rec {

    tsuki = {
        module  = activate ./module;
        trivial = activate ./trivial;
        nixpkgs = activate ./nixpkgs;
        list    = activate ./list;
    };

    inherit ( tsuki.module )
        listAllModules
    ;

    inherit ( tsuki.trivial )
        doNothing
        nixos2colmena
        eachSystem
    ;

    inherit ( tsuki.nixpkgs )
        onceride oncerideDrv
        brewNixpkgs
        brewShells
        brewOS
        libsToCompilerEnvvars
        useElectronBin
    ;

    inherit ( tsuki.list )
        appendElem
    ;

}
