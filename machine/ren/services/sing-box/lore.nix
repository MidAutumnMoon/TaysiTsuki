{
    listenPort = 7891;
    noproxyDomains = [ "clash.418.im" "dnscrypt.418.im" "music.418.im" "proxy.418.im" "router.418.im" "qbit.418.im" "wpad.418.im" "local" "tailscale.418.im" ];
    clashApiAddr = "127.0.0.1:9098";

    # :: string -> path
    # Return the path of geosite data of $name
    geositeDataOf = name:
        let pkg = "/nix/store/dn1gmwaqy63mhwpb3mxgg8s5a0xma8x6-sing-geosite-20250608120644"; in
        let dir = "${pkg}/share/sing-box/rule-set"; in
        "${dir}/geosite-${name}.srs";
}
# vim: ft=nix:
