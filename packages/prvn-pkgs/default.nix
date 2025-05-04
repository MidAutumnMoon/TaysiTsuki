{
    lib,
    buildPackages,
    runCommandNoCC,
    buildGoModule,

    tsuki,
    dnscrypt-proxy,
}:

rec {

    upx-pack = input:
        assert builtins.isString input;
        let exename = builtins.baseNameOf input; in
        runCommandNoCC exename {} ''
            mkdir -pv "$out/bin"
            "${lib.getExe buildPackages.upx}" \
                --lzma --best \
                "${input}" -o "$out/bin/${exename}"
        '';

    all = [
        ssserver
        hysteria
        dnscrypt
    ];

    ssserver =
        upx-pack ( lib.getExe' tsuki.shadowsocks "ssserver" );

    hysteria =
        upx-pack ( lib.getExe tsuki.hysteria );

    dnscrypt =
        # N.B. CGO must be disabled which makes it not depend on ld.so.
        # Otherwise, upx will try to call ld.so at startup, and also because of
        # the path is hardcoded then compressed by upx, nix won't be able to
        # scan for runtime dependencies of the output, i.e. ld.so (glibc)
        # in this case, the upx-packed executable won't start on environment
        # where there's no glibc in the store, e.g. systemd portable service :/
        { env.GOAMD64 = "v3"; env.CGO_ENABLED = 0; }
        |> ( it: args: buildGoModule <| args // it )
        |> ( it: dnscrypt-proxy.override { buildGoModule = it; } )
        |> ( it: upx-pack <| lib.getExe it )
    ;

}
