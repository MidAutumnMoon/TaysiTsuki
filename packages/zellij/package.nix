{
    lib,
    stdenv,
    tsuki,
    zellij,
}:

lib.onceride zellij

{
    rustPlatform = tsuki.rust;
}

(old: {
    doCheck = false;

    # disable web server
    postPatch = old.postPatch or "" + ''
        substituteInPlace "Cargo.toml" \
          --replace-fail ', "web_server_capability"' ""
      '';

    env.CARGO_PROFILE_RELEASE_LTO = "thin";
    env.RUSTFLAGS = with stdenv; toString <|
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;
})
