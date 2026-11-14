{
    stdenv,
    lib,
    niri,
    ...
}:

lib.onceride niri

{
    withScreencastSupport = false;
}

(oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
        ./squircle-v26.04.patch
    ];

    doCheck = false;

    env.RUSTFLAGS =
        oldAttrs.env.RUSTFLAGS
        + lib.optionalString stdenv.hostPlatform.isx86_64
            " -Ctarget-cpu=x86-64-v3"
    ;
})
