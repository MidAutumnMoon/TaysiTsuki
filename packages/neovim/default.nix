{
    lib,
    symlinkJoin,
    runCommand,
    makeWrapper,

    neovim-unwrapped,
    vimPlugins,

    # Enable all parsers adds about 200MB to the closure.
    withAllTsParsers ? true,
}:

let

    ts-parsers = let
        paths = vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
        unwanted = [
            "verilog" "gnuplot" "v" "slang" "ssh_config"
            "objc" "nim" "racket" "commonlisp" "scheme"
        ];
    in runCommand "ts-parsers" {} ''
        declare dest="$out/nvim/site/parser";
        mkdir -pv "$dest"
        ${
            paths
            |> map ( drv: '' cp -Lv ${drv}/parser/*.so "$dest" '' )
            |> lib.concatStringsSep "; "
        }
        ${
            unwanted
            |> map ( name: "-name ${name}.so" )
            |> lib.concatStringsSep " -or "
            |> ( ns: "find $dest -type f \\( ${ns} \\) -exec rm -v '{}' + " )
        }
    '';

    xdgDataDirs = [
        "/run/current-system/sw/share"
        ( lib.optional withAllTsParsers ( toString ts-parsers ) )
    ]
    |> lib.flatten
    |> lib.concatStringsSep ":"
    ;

    xdgConfigDirs = lib.concatStringsSep ":" [
        "/etc/xdg"
        "/run/current-system/sw/etc/xdg"
    ];

in

symlinkJoin {

    name = "neovim";

    paths = [
        neovim-unwrapped
    ];

    nativeBuildInputs = [
        makeWrapper
    ];

    postBuild = ''
        rm -v "$out/bin/nvim"

        # nvim is smart enough to figure out his real
        # path, so no need to include the runtime in wrapper
        rm -r "$out/share/nvim"

        makeWrapper \
            "${neovim-unwrapped}/bin/nvim" "$out/bin/nvim" \
            --inherit-argv0 \
            --set XDG_DATA_DIRS "${xdgDataDirs}" \
            --set XDG_CONFIG_DIRS "${xdgConfigDirs}"

        ln -s "$out/bin/nvim" "$out/bin/vi"
        ln -s "$out/bin/nvim" "$out/bin/vim"
    '';


    passthru = {
        inherit
            ts-parsers
            neovim-unwrapped
        ;
    };

    meta.mainProgram = "nvim";

}
