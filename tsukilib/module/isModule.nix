lib:


let

    inherit ( builtins )
        isPath
        pathExists
    ;

in

{

    # isModule :: path -> bool
    #
    # A module is a directory containing a default.nix,
    # despite its content.
    #
    isModule = path:
        isPath path && pathExists ( path + "/default.nix" );

}
