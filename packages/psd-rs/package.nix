{
    lib,
    tsuki,
    makeWrapper,
    rsync,
    fuse-overlayfs,
    coreutils,
    util-linux,
    procps,
    flatpak,
    installShellFiles,
}:

tsuki.rust.buildRustPackage rec {
    pname = "psd-rs";
    version = "0.1.0";

    inherit (tsuki.workspace)
        src cargoLock;

    cargoBuildFlags = "-p ${pname}";
    doCheck = false;

    # Wrap psd with store-path runtime deps so it works without polluting
    # global PATH. fusermount3 is NOT included here -- it needs SUID and
    # comes from /run/wrappers/bin on NixOS (set in the service environment).
    nativeBuildInputs = [
        makeWrapper
        installShellFiles
    ];

    postInstall = ''
        # Generate and install shell completions from the unwrapped
        # binary (before wrapProgram moves it). Completions only need
        # clap metadata, no runtime deps.
        bin="$out/bin/psd"
        installShellCompletion --cmd psd \
            --bash <("$bin" completions bash) \
            --fish <("$bin" completions fish) \
            --zsh  <("$bin" completions zsh)

        # Wrap psd with store-path runtime deps so it works without
        # polluting global PATH. fusermount3 is NOT included here -- it
        # needs SUID and comes from /run/wrappers/bin on NixOS (set in
        # the service environment).
        wrapProgram $out/bin/psd \
            --prefix PATH : ${lib.makeBinPath [
                rsync fuse-overlayfs coreutils util-linux procps flatpak
            ]}
    '';

    meta.mainProgram = "psd";
}
