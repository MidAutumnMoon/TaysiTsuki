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

    parsersBundle = let
        parsers = vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
        unwanted = [
            "verilog" "gnuplot" "v" "slang" "ssh_config"
            "objc" "nim" "racket" "commonlisp" "scheme"
        ];
    in runCommand "treesitter-parser-bundle" {} ''
        declare dest="$out/nvim/site/parser";
        mkdir -pv "$dest"
        ${
            # Generate cp cmds to copy .so
            parsers
            |> map ( it: '' cp -Lv ${it}/parser/*.so "$dest" '' )
            |> lib.concatStringsSep "; "
        }
        ${
            # Generate a find command to remove unwanted parsers' .so files.
            unwanted
            |> map ( name: "-name ${name}.so" )
            |> lib.concatStringsSep " -or "
            |> ( ns: "find $dest -type f \\( ${ns} \\) -exec rm -v '{}' + " )
            # Why not filter out these parsers when copying?
            # Because find is tedious to work with if rule gets complex.
        }
    '';

    xdgDataDirs = [
        "/run/current-system/sw/share"
        ( lib.optional withAllTsParsers ( toString parsersBundle ) )
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

    postBuild = /* bash */ ''
        rm -v "$out/bin/nvim"

        makeWrapper \
            "${lib.getExe neovim-unwrapped}" "$out/bin/nvim" \
            --inherit-argv0 \
            --set XDG_DATA_DIRS "${xdgDataDirs}" \
            --set XDG_CONFIG_DIRS "${xdgConfigDirs}"

        ln -s "$out/bin/nvim" "$out/bin/vi"
        ln -s "$out/bin/nvim" "$out/bin/vim"
    '';

    passthru = {
        inherit
            parsersBundle
            neovim-unwrapped
        ;
    };

    meta.mainProgram = "nvim";

}
