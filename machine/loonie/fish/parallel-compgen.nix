{ lib, config, pkgs, ... }:

let

    # Python script bundled with fish for generating completion.
    compGenerator =
        config.programs.fish.package
        |> ( it: "${it}/share/fish/tools/create_manpage_completions.py" );

    pyInterpreter =
        pkgs.python3.pythonOnBuildForHost.interpreter;

    man = let
        mandbCfg = config.documentation.man.man-db;
    in {
        enable = mandbCfg.enable;
        manpages = "${mandbCfg.manualPages}/share/man";
    };

in lib.mkIf man.enable {

    # 1) find
    # - Specify -maxdepth to exclude locale dirs e.g. de/, fr/
    # - Exclude section 3 i.e. posix api docs
    #
    # 2) xargs
    # - $NIX_BUILD_CORES parallel jobs with each job process 100 pages
    #
    # 3) compGenerator
    # - N.B. --keep so that parallel jobs won't delete each other's works
    passthru."fish-completion" =
        pkgs.runCommand "generated-completion" {} ''
            mkdir -pv "$out"
            find "${man.manpages}" \
                -maxdepth 2 \
                -path "*man[1,4-8]/*.gz" \
            | xargs --max-procs="$NIX_BUILD_CORES" --max-args=100 \
                ${pyInterpreter} ${compGenerator} --keep --directory "$out"
        '';

    environment.extraSetup = /* bash */ ''
        mkdir -p "$out/etc/fish"
        ln -sf "${config.passthru.fish-completion}" "$out/etc/fish/completions"
    '';

}
