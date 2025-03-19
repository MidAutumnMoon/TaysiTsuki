{
    lib,
    newScope,
}:

lib.makeScope newScope ( self: let

    callPackage =
        self.newScope { inherit lib; };

in {

    upx-pack =
        callPackage ./upx.nix {};

    all = with self; [
        pn-ssserver
        pn-hysteria
        pn-dnscrypt
    ];

    pn-ssserver =
        callPackage ./ssserver.nix {};

    pn-hysteria =
        callPackage ./hysteria.nix {};

    pn-dnscrypt =
        callPackage ./dnscrypt.nix {};

} )
