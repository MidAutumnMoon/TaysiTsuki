{ lib, config, pkgs, ... }:

let

    inherit ( lib )
        mkOption
        types
    ;

    fishCfg = config.programs.fish;
    manCfg = config.documentation.man.man-db;

    generator =
        "${fishCfg.package}/share/fish/tools/create_manpage_completions.py";

    python =
        pkgs.python3.pythonOnBuildForHost.interpreter;

in

{

    options.programs.fish = {
        __generatedCompletion = mkOption {
            type = with types; nullOr package;
            description = ''
                Fish completion generated from manpages.
            '';
            default = null;
        };
    };

    config = lib.mkIf ( fishCfg.enable && manCfg.enable ) {

        # 1) find
        # - "-maxdepth" for excluding locale manpages because
        #   they are one level deeper than default English ones.
        #
        # 2) xargs
        # - $NIX_BUILD_CORES jobs with each job processing 100 pages
        #
        # 3) compGenerator
        # - "--keep" is important, otherwise later finished jobs
        #   will delete prio generated completion because they
        #   don't belong to it
        programs.fish.__generatedCompletion =
            pkgs.runCommand "fish-generated-completion"
            {}
            ''
                mkdir -pv "$out"
                find "${manCfg.manualPages}/share/man" \
                    -maxdepth 2 \
                    -path '*man[1,4-8]/*.gz' \
                | xargs --max-procs="$NIX_BUILD_CORES" \
                        --max-args="100" \
                    '${python}' '${generator}' \
                        --keep --directory "$out" 2>/dev/null
            '';

    };

}
