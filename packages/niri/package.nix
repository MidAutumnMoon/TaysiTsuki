{
    stdenv,
    lib,
    niri,
    rustPlatform,
    ...
}:

lib.onceride niri

{
    withScreencastSupport = false;
}

(oldAttrs: {
    patches = (oldAttrs.patches or [])
        ++ [ ./mimalloc.patch ];

    cargoDeps = rustPlatform.fetchCargoVendor {
        inherit (oldAttrs) pname version src;
        patches = [ ./mimalloc.patch ];
        hash = "sha256-N+n2VU/15jF1mLmMmdulb2O1MP/4ehwMAGxy0IZ4QxU=";
    };

    doCheck = false;

    env.RUSTFLAGS =
        oldAttrs.env.RUSTFLAGS
        + lib.optionalString stdenv.hostPlatform.isx86_64
            " -Ctarget-cpu=x86-64-v3"
    ;
})
