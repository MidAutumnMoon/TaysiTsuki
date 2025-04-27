{
    lib,
    newScope,

    symlinkJoin,
}:

lib.makeScope newScope ( self: let

    inherit ( self )
        callPackage
    ;

in {

    ",rclone" = callPackage ./rclone.nix {};

    ",sync" = callPackage ./sync.nix {
        myRclone = self.",rclone";
    };

    allSuiteCombined = symlinkJoin {
        name = "phia-suite";
        paths =
            [
                ",rclone"
                ",sync"
            ]
            |> ( it: lib.getAttrs it self )
            |> lib.attrValues;
    };

} )
