{
    lib,
    symlinkJoin,
    makeWrapper,
    neovim-unwrapped,
}:

let

    xdgDataDirs = [
        "/run/current-system/sw/share"
    ]
        |> lib.flatten
        |> lib.concatStringsSep ":";

    xdgConfigDirs = lib.concatStringsSep ":" [
        "/etc/xdg"
        "/run/current-system/sw/etc/xdg"
    ];

in

symlinkJoin {

    name = "neovim";

    paths = [ neovim-unwrapped ];
    nativeBuildInputs = [ makeWrapper ];

    postBuild = /* bash */ ''
        rm -v "$out/bin/nvim"

        makeWrapper \
            "${lib.getExe neovim-unwrapped}" "$out/bin/nvim" \
            --inherit-argv0 \
            --set UV_THREADPOOL_SIZE "16" \
            --set XDG_DATA_DIRS "${xdgDataDirs}" \
            --set XDG_CONFIG_DIRS "${xdgConfigDirs}"

        ln -s "$out/bin/nvim" "$out/bin/vi"
        ln -s "$out/bin/nvim" "$out/bin/vim"
    '';

    passthru = {
        inherit neovim-unwrapped;
    };

    meta.mainProgram = "nvim";

}
