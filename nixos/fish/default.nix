{ lib, config, pkgs, ... }:

lib.mkMerge [

{

    # Fish is launched by Bash, this module becomes useless.
    programs.fish.enable = false;

    environment.pathsToLink = [
        "/share/fish/vendor_conf.d"
        "/share/fish/vendor_completions.d"
        "/share/fish/vendor_functions.d"
    ];

}

( let

    # Reimplement what fish.nix module has done and make it more parallel.

    manCfg = config.documentation.man.man-db;
    fish = config.programs.fish.package;

    manpages = "${manCfg.manualPages}/share/man";

    python = pkgs.python3.pythonOnBuildForHost.interpreter;
    comp_generator = "${fish}/share/fish/tools/create_manpage_completions.py";

in lib.mkIf manCfg.enable {

    passthru."fish-completions" =
        pkgs.runCommandNoCC "fish-completions" {} ''
            mkdir -pv $out

            # find
            # - use -maxdepth to exclude locale manpages
            # - ignore manpages from section 3 (C functions)
            #
            # xargs
            # - run $NIX_BUILD_CORES parallel jobs
            # - each job get 100 inputs
            #
            # fish's completion generator
            # - --keep so that parallel jobs won't delete each other's works
            # - output to $out
            find "${manpages}" \
                -maxdepth 2 \
                -path "*man[1,4-8]/*.gz" \
            | xargs --max-procs="$NIX_BUILD_CORES" \
                    --max-args=100 \
                ${python} ${comp_generator} --keep --directory "$out"
        ''
    ;

    environment.etc."fish/generated_completions".source =
        config.passthru."fish-completions"
    ;

    environment.etc."fish/config.fish".text = /* fish */ ''
        # Ensure the /etc/fish/generated_completions is in fish_complete_path
        # and unique
        set -l gen_comp_path "/etc/fish/generated_completions"

        set -l idx ( contains --index "$gen_comp_path" $fish_complete_path )
            and set --erase fish_complete_path[$idx]

        set --append fish_complete_path "$gen_comp_path"
    '';

} )

]
